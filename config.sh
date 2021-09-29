#!/bin/sh
clear

# P_AMBIENT=${1:-dev}
P_DOCKER_USERNAME=${1:-mqttAdmin}
P_DOCKER_USER_KEY=${2:-$(< /dev/urandom tr -dc A-Z-a-z-0-9 | head -c${3:-12};echo;)}
P_OPTION=${3:-host}
P_HOSTNAME=${4:-$(hostname -f)}
P_CA_ORG=${5:-$(echo '/O=OwnTracks.org/OU=generate-CA/emailAddress=nobody@example.net')}
# P_CA_KEY=${6:-$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${6:-32};echo;)}
IPLIST=${6:-$(echo "127.0.0.1")}
HOSTLIST=${7:-$(echo "mqtt.example.com server.example.com")}
P_CA_FORMAT=${8:-crt)}

echo "-----Params received-----"
# echo "Ambient: $P_AMBIENT"
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
cd ca_certificates || exit
source ./generate-CA.sh $P_OPTION $P_HOSTNAME $P_CA_ORG $IPLIST $HOSTLIST $P_CA_FORMAT
cd ..
echo "1: done"

#-------------------------------------------------------------------------------------------------
printf '\e[1;32m%-6s\e[m' "2 Configuring config file..."
echo ""
cd config || exit
sed -i "s/SERVER_NAME/$P_HOSTNAME/g" mosquitto.conf
if [[ "$P_CA_FORMAT" == "pem" ]]; then
    sed -i "s/.crt/.pem/g" mosquitto.conf
    sed -i "s/.keys/.pem/g" mosquitto.conf
else
    sed -i "s/.keys/.key/g" mosquitto.conf
fi

chmod 775 mosquitto.conf

echo "2: done"

#-------------------------------------------------------------------------------------------------
printf '\e[1;32m%-6s\e[m' "3 Creating and configuring password file for mosquitto..."
echo ""
cd config.d || exit
sudo touch passwd
#sudo apt-get install mosquitto mosquitto-clients -y
#sudo mosquitto_passwd -b passwd $P_DOCKER_USERNAME $P_DOCKER_USER_KEY
sudo chmod 775 passwd
sudo chmod 775 password.conf
cd ..
cd ..
echo "3: done"

#-------------------------------------------------------------------------------------------------
printf '\e[1;32m%-6s\e[m' "4 Getting mosquitto image if it not exists..."
echo ""

docker pull eclipse-mosquitto:latest

echo "4: done"

#-------------------------------------------------------------------------------------------------
printf '\e[1;32m%-2s\e[m' "5 Creating docker container for mosquitto." 
echo ""

if [[ "$P_CA_FORMAT" == "pem" ]]; then
    sed -i "s/.crt/.pem/g" create-container.sh
    sed -i "s/.keys/.pem/g" create-container.sh
    sed -i "s/.keys/.pem/g" create-container.sh
else
    sed -i "s/.keys/.key/g" create-container.sh
fi

source ./create-container.sh $P_HOSTNAME

# sudo docker run --init -d \
# --name="eclipse-mosquitto" \
# --restart always \
# -p 8883:8883 \
# -e "TZ=America/Argentina/Buenos_Aires" \
# -v $(pwd)/config/mosquitto.conf:/mosquitto/config/mosquitto.conf \
# -v $(pwd)/config/config.d:/mosquitto/config.d \
# -v $(pwd)/log:/mosquitto/log \
# -v $(pwd)/data:/mosquitto/data \
# -v $(pwd)/ca_certificates/ca.crt:/ca_certificates/ca-cert.crt \
# -v $(pwd)/ca_certificates/server_certs/$P_HOSTNAME-cert.crt:/ca_certificates/server_certs/$P_HOSTNAME-cert.crt \
# -v $(pwd)/ca_certificates/server_certs/$P_HOSTNAME-key.key:/ca_certificates/server_certs/$P_HOSTNAME-key.key \
# eclipse-mosquitto

echo "5: done"

#-------------------------------------------------------------------------------------------------