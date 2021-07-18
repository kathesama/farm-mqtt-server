<link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.15.2/css/all.css" integrity="sha384-vSIIfh2YWi9wW0r9iZe7RJPrKwp6bG+s9QZMoITbCckVJqGCCRhc+ccxNcdpHuYu" crossorigin="anonymous">

[<img src="https://img.shields.io/badge/Linkedin-kathesama-blue?style=for-the-badge&logo=linkedin">](https://www.linkedin.com/in/kathesama)
<br>
![VSCode](https://img.shields.io/badge/Made%20for-VSCode-1f425f.svg?style=for-the-badge&logo=visualstudio)
![Open In Collab](https://img.shields.io/badge/Works%20with-Docker-blue?style=for-the-badge&logo=docker)
<br>
[![GitHub issues](https://img.shields.io/github/issues/kathesama/farm-mqtt-server?style=plastic)](https://github.com/kathesama/farm-mqtt-server/issues)
[![GitHub forks](https://img.shields.io/github/forks/kathesama/farm-mqtt-server?style=plastic)](https://github.com/kathesama/farm-mqtt-server/network)
[![GitHub stars](https://img.shields.io/github/stars/kathesama/farm-mqtt-server?style=plastic)](https://github.com/kathesama/farm-mqtt-server/stargazers)
![GitHub last commit](https://img.shields.io/github/last-commit/kathesama/farm-mqtt-server?color=red&style=plastic)
![GitHub top language](https://img.shields.io/github/languages/top/kathesama/farm-mqtt-server?style=plastic)
<br>
[![GitHub license](https://img.shields.io/github/license/kathesama/farm-mqtt-server?style=plastic)](https://github.com/kathesama/farm-mqtt-server/blob/main/LICENSE)
![GitHub repo size](https://img.shields.io/github/repo-size/kathesama/farm-mqtt-server?style=plastic)
<br>

# farm-mqtt-server
Mqtt server for farm project


execute 
> source ./config.sh <dev|prod> <dockerUser> [dockerUserPassword] <host|client> [hostname] [caCertPassword] <CA_ORG> <P_CA_FORMAT> 

* Values with <> are required<br>
* Values with [] are optional but **MUST BE PROVIDED** two single quotes ''
* At CA_ORG: <br>
    C: country
    ST: state
    L: location
    O: organization name
    OU: organizative unity

Params:
<!-- 1. 'dev|prod': This indicates which ambient will be performed on, by default is *dev* -->
1. 'dockerUser': Docker user for mosquitto server, by default is *mqttAdmin*
2. 'dockerUserPassword': Docker password for user for mosquitto server, default is *a random string* 
3. 'host|client': This indicates which operation will be performed on, by default is *host*
4. 'hostname': Name related with certs generated, this indicates file name and host's name
<!-- 6. 'caCertPassword': Ca Cert password related for security purposes, default is *a random string*  -->
5. 'CA_ORG': this gives the remaining parameters for the CA cert config, <br>
    > estructure **MUST BE LIKE** (default value): '/C=AR/ST=CABA/L=Buenos_Aires_Capital//O=OwnTracks.org/OU=generate-CA/emailAddress=nobody@example.net' 
6. 'P_CA_FORMAT': output certs format, <crt|pem>, **by default is *pem***


example:
>source ./config.sh mqttDesa b69FLW7WzMdpv host srv-pi-desa '/C=AR/ST=CABA/L=Buenos_Aires_Capital/O=kathevigs/OU=generate-CA/emailAddress=kathesama@gmail.com' pem

---

For clients certs execute
> source ./ca_certificates/generate-CA.sh <client> <clientName> [CA_ORG] <P_CA_FORMAT>

Params:
1. 'host|client': This indicates which operation will be performed on, by default is *host* but it **MUST BE PROVIDED** client
2. 'clientName': Name related with certs generated, this indicates file name and host's name, by default is the server's name but it **MUST BE PROVIDED** client name
3. 'CA_ORG': this gives the remaining parameters for the CA cert config, <br>
    > estructure **MUST BE LIKE** (default value): '/C=AR/ST=CABA/L=Buenos_Aires_Capital/O=OwnTracks.org/OU=generate-CA/emailAddress=nobody@example.net'
4. 'P_CA_FORMAT': output certs format, <crt|pem>, **by default is *crt***    

example:
> cd ca_certificates <br>
> source ./generate-CA.sh client ESPSensorDev-001 '/C=AR/ST=CABA/L=Buenos_Aires_Capital/O=kathevigs/OU=generate-CA/emailAddress=kathesama@gmail.com' pem

Checking mqtt server, execute to publish

```
mosquitto_pub --cafile ca_certificates/ca.crt \
--cert ca_certificates/client_certs/ESPSensorDev-001/ESPSensorDev-001.crt \
--key ca_certificates/client_certs/ESPSensorDev-001/ESPSensorDev-001.key \
-h 10.0.0.12 \-u mqttDesa \
-P b69FLW7WzMdpv \
-t casa/laboratorio/switch1/set \
-m "hola desde desa" \
-p 8883 -d
```
And this one for listening
```
mosquitto_sub --cafile ca_certificates/ca.crt \
--cert ca_certificates/client_certs/ESPSensorDev-001/ESPSensorDev-001.crt \
--key ca_certificates/client_certs/ESPSensorDev-001/ESPSensorDev-001.key \
-v -t casa/laboratorio/switch1 \
-h 10.0.0.12 \
-p 8883 \
-u mqttDesa \
-P b69FLW7WzMdpv \
-d
```

