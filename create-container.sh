#!/bin/sh
P_HOSTNAME=${1:-$(hostname -f)}

sudo docker run --init -d \
--name="eclipse-mosquitto" \
--restart always \
-p 8883:8883 \
-e "TZ=America/Argentina/Buenos_Aires" \
-v $(pwd)/config/mosquitto.conf:/mosquitto/config/mosquitto.conf \
-v $(pwd)/config/config.d:/mosquitto/config.d \
-v $(pwd)/log:/mosquitto/log \
-v $(pwd)/data:/mosquitto/data \
-v $(pwd)/ca_certificates/ca.crt:/ca_certificates/ca-cert.crt \
-v $(pwd)/ca_certificates/server_certs/$P_HOSTNAME-cert.crt:/ca_certificates/server_certs/$P_HOSTNAME-cert.crt \
-v $(pwd)/ca_certificates/server_certs/$P_HOSTNAME-key.keys:/ca_certificates/server_certs/$P_HOSTNAME-key.keys \
eclipse-mosquitto