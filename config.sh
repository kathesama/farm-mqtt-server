#!/bin/sh
clear

P_AMBIENT=${1:-dev}
P_DOCKER_USERNAME=${2:-mqttAdmin}
P_DOCKER_USER_KEY=${3:-$(< /dev/urandom tr -dc A-Z-a-z-0-9 | head -c${3:-12};echo;)}
P_OPTION=${4:-host}
P_HOSTNAME=${5:-$(hostname -f)}
P_CA_ORG=${7:-$(echo '/O=OwnTracks.org/OU=generate-CA/emailAddress=nobody@example.net')}
# P_CA_KEY=${6:-$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${6:-32};echo;)}
P_CA_FORMAT=${8:-crt)}

echo "-----Params received-----"
echo "Ambient: $P_AMBIENT"
echo "Docker MQTT Server Username: $P_DOCKER_USERNAME"
printf '\e[1;32m%-6s\e[m' "Docker MQTT Username password: "
echo "$P_DOCKER_USER_KEY"
echo "Ca Cert type: $P_OPTION"
echo "Hostname got: $P_HOSTNAME"
# printf '\e[1;32m%-6s\e[m' "Cert pass is: "
# echo "$P_CA_KEY"
echo "CA_ORG values got: $P_CA_ORG"
echo "Output format values got: $P_CA_FORMAT"
echo "----------"

#-------------------------------------------------------------------------------------------------
printf "\n"
printf '\e[1;31m%-6s\e[m' "Proceding to config: [$1]..."
printf "\n"

printf '\e[1;32m%-6s\e[m' "1 Configuring certs..."
echo ""
chmod 700 ca_certificates
cd ca_certificates
source ./generate-CA.sh $P_OPTION $P_HOSTNAME $P_CA_ORG $P_CA_FORMAT
cd ..
echo "1: done"

#-------------------------------------------------------------------------------------------------
printf '\e[1;32m%-6s\e[m' "2 Configuring config file..."
echo ""
cd config
sed -i "s/SERVER_NAME/$P_HOSTNAME/g" mosquitto.conf
chmod 775 mosquitto.conf

echo "2: done"

#-------------------------------------------------------------------------------------------------
printf '\e[1;32m%-6s\e[m' "3 Creating and configuring password file for mosquitto..."
echo ""
cd config.d
touch "passwd"
sudo mosquitto_passwd -b passwd $P_DOCKER_USERNAME $P_DOCKER_USER_KEY
sudo chmod 775 passwd
sudo chmod 775 password.conf
cd ..
cd ..
echo "3: done"

#-------------------------------------------------------------------------------------------------
printf '\e[1;32m%-6s\e[m' "4 Getting mosquitto image if it not exists..."
echo ""

docker pull eclipse-mosquitto:latest
sudo apt-get install mosquitto mosquitto-clients -y
echo "4: done"

#-------------------------------------------------------------------------------------------------
printf '\e[1;32m%-2s\e[m' "5 Creating docker container for mosquitto." 
echo ""

sudo docker run --init -d \
--name="eclipse-mosquitto" \
--restart always \
-p 8883:8883 \
-e "TZ=America/Argentina/Buenos_Aires" \
-v $(pwd)/config/mosquitto.conf:/mosquitto/config/mosquitto.conf \
-v $(pwd)/config/config.d:/mosquitto/config.d \
-v $(pwd)/log:/mosquitto/log \
-v $(pwd)/data:/mosquitto/data \
-v $(pwd)/ca_certificates/ca.crt:/ca_certificates/ca.crt \
-v $(pwd)/ca_certificates/server_certs/$P_HOSTNAME.crt:/ca_certificates/server_certs/$P_HOSTNAME.crt \
-v $(pwd)/ca_certificates/server_certs/$P_HOSTNAME.key:/ca_certificates/server_certs/$P_HOSTNAME.key \
eclipse-mosquitto

echo "5: done"

#-------------------------------------------------------------------------------------------------