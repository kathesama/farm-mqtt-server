#!/bin/sh
clear

P_AMBIENT=${1:-dev}
P_DOCKER_USERNAME=${2:-mqttAdmin}
P_DOCKER_USER_KEY=${3:-$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${3:-32};echo;)}
P_OPTION=${4:-host}
P_HOSTNAME=${5:-$(hostname -f)}
P_CA_KEY=${6:-$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${6:-32};echo;)}
P_CA_ORG=${7:-$(echo '/O=OwnTracks.org/OU=generate-CA/emailAddress=nobody@example.net')}

echo "-----Params received-----"
echo "Ambient: $P_AMBIENT"
echo "Docker MQTT Server Username: $P_DOCKER_USERNAME"
printf '\e[1;32m%-6s\e[m' "Docker MQTT Username password: "
echo "$P_DOCKER_USER_KEY"
echo "Ca Cert type: $P_OPTION"
echo "Hostname got: $P_HOSTNAME"
printf '\e[1;32m%-6s\e[m' "Cert pass is: "
echo "$P_CA_KEY"
echo "CA_ORG values got: $P_CA_ORG"
echo "----------"

#-------------------------------------------------------------------------------------------------
printf "\n"
printf '\e[1;31m%-6s\e[m' "Proceding to config: [$1]..."
printf "\n"

printf '\e[1;32m%-6s\e[m' "1 Configuring certs..."
echo ""
chmod 700 ca_certificates
cd ca_certificates
# source ./generate-CA.sh $P_OPTION $P_HOSTNAME $P_CA_KEY $P_CA_ORG
cd ..
echo "1: done"

printf '\e[1;32m%-6s\e[m' "2 Configuring config file..."
echo ""
cd config.d
sed -i "s/SERVER_NAME/$P_HOSTNAME/g" mosquitto.conf
sed -i "s/AMBIENT/$P_AMBIENT/g" password.conf
echo "2: done"

printf '\e[1;32m%-6s\e[m' "3 Creating password file for mosquitto..."
echo ""

# if [[ $P_AMBIENT == "dev" ]]; then  		
sudo mosquitto_passwd -b "mosquitto-$P_AMBIENT.passwd" $P_DOCKER_USERNAME $P_DOCKER_USER_KEY
# else
#     sudo mosquitto_passwd -b mosquitto-prod.passwd $P_DOCKER_USERNAME $P_DOCKER_USER_KEY
# fi
cd ..
echo "3: done"


printf '\e[1;32m%-6s\e[m' "4 Getting mosquitto image if it not exists..."
echo ""

#docker pull eclipse-mosquitto:latest
#sudo apt-get install mosquitto mosquitto-clients -y
echo "4: done"