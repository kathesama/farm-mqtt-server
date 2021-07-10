# farm-mqtt-server
Mqtt server for farm project

execute 
source ./ca_certificates.sh <host|client> 
> source ./config.sh <dev|prod> <dockerUser> [dockerUserPassword] <host|client> [hostname] [caCertPassword] <CA_ORG> 

* Values with <> are required<br>
* Values with [] are optional but **MUST BE PROVIDED** two single quotes ''

Params:
1. 'dev|prod': This indicates which ambient will be performed on, by default is *dev*
2. 'dockerUser': Docker user for mosquitto server, by default is *mqttAdmin*
3. 'dockerUserPassword': Docker password for user for mosquitto server, default is *a random string* 
4. 'host|client': This indicates which operation will be performed on, by default is *host*
5. 'hostname': Name related with certs generated, this indicates file name and host's name
6. 'caCertPassword': Ca Cert password related for security purposes, default is *a random string* 
7. 'CA_ORG': this gives the remaining parameters for the CA cert config, <br>
    > estructure **MUST BE LIKE** (default value): '/O=OwnTracks.org/OU=generate-CA/emailAddress=nobody@example.net'

    O: organization


example:
>source ./config.sh desa mqttDesa '' host srv-pi-desa '' '/C=AR/ST=CABA/L=Buenos_Aires_Capital/O=kathevigs/OU=generate-CA/emailAddress=kathesama@gmail.com'
