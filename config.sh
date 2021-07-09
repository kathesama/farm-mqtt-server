#!/bin/sh
clear

P_AMBIENT=${1:-dev}
P_DOCKER_USERNAME=${2:-mqttAdmin}
P_DOCKER_USER_KEY=${3:-$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32};echo;)}
P_OPTION=${4:-host}
P_HOSTNAME=${5:-$(hostname -f)}
P_CA_KEY=${6:-$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32};echo;)}
P_CA_ORG=${7:-$(echo '/O=OwnTracks.org/OU=generate-CA/emailAddress=nobody@example.net')}

echo "Params received:"
echo "Ambient: $P_AMBIENT"
echo "Docker MQTT Server Username: $P_DOCKER_USERNAME"
echo "Docker MQTT Username password: $P_DOCKER_USER_KEY"
echo "Ca Cert type: $P_OPTION"
echo "Hostname got: $P_HOSTNAME"
printf '\e[1;32m%-6s\e[m' "Cert pass is: "
echo "$P_CA_KEY"
printf '\e[1;32m%-6s\e[m' "Cert pass is: "
echo "$P_CA_KEY"
echo "CA_ORG values got: $P_CA_ORG"

#-------------------------------------------------------------------------------------------------
printf "\n"
printf '\e[1;31m%-6s\e[m' "Proceding to config: [$1]..."
printf "\n"
printf '\e[1;32m%-6s\e[m' "1 Getting mosquitto image if it not exists..."
echo ""

docker pull eclipse-mosquitto:latest
sudo apt-get install mosquitto mosquitto-clients -y

printf '\e[1;32m%-6s\e[m' "2 Configuring certs..."
echo ""
chmod 700 ca_certificates
cd ca_certificates
source ./generate-CA.sh $P_OPTION $P_HOSTNAME $P_CA_KEY $P_CA_ORG
sudo mv "$P_HOSTNAME.crt" "$P_HOSTNAME.key" mqtt_certs/
cd ..

printf '\e[1;32m%-6s\e[m' "3 Configuring config file..."
echo ""
cd config
sed -i 's/SERVER_NAME/$P_HOSTNAME/g' mosquitto.conf
