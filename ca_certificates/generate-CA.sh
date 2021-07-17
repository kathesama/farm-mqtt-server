#!/usr/bin/env bash
#(@)generate-CA.sh - Create CA key-pair and server key-pair signed by CA

# Copyright (c) 2013-2020 Jan-Piet Mens <jpmens()gmail.com>
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. Neither the name of mosquitto nor the names of its
#    contributors may be used to endorse or promote products derived from
#    this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

#
# Usage:
#	./generate-CA.sh		creates ca.crt and server.{key,crt}
#	./generate-CA.sh hostname	creates hostname.{key,crt}
#	./generate-CA.sh client email	creates email.{key,crt}
#
# Set the following optional environment variables before invocation
# to add the specified IP addresses and/or hostnames to the subjAltName list
# These contain white-space-separated values
#
#	IPLIST="172.13.14.15 192.168.1.1"
#	HOSTLIST="a.example.com b.example.com"

set -e

export LANG=C

echo "**********************************"
echo "******** generate-CA *************"
echo "**********************************"

kind=server
P_OPTION=${1:-host}
P_HOSTNAME=${2:-$(hostname -f)}
CA_ORG=${3:-$(echo '/C=AR/ST=CABA/L=Buenos_Aires_Capital/O=OwnTracks.org/OU=generate-CA/emailAddress=nobody@example.net')}
P_CA_FORMAT=${4:-crt)}

echo "Ca Cert type: $P_OPTION"
echo "Hostname got: $P_HOSTNAME"
# printf '\e[1;31m%-6s\e[m' "Cert pass is: "
# echo "$P_CA_KEY"
echo "CA_ORG values got: $CA_ORG"
echo "Output format values got: $P_CA_FORMAT"

if [[ $P_OPTION == "host" ]]; then
  	kind=server
	host=$P_HOSTNAME
else
	kind=client
	CLIENT=$P_HOSTNAME
fi

# if [ $# -ne 2 ]; then
# 	kind=server
# 	host=$(hostname -f)
# 	if [ -n "$1" ]; then
# 		host="$1"
# 	fi
# else
# 	kind=client
# 	CLIENT="$2"
# fi

[ -z "$USER" ] && USER=root

DIR=${TARGET:='.'}
# A space-separated list of alternate hostnames (subjAltName)
# may be empty ""
ALTHOSTNAMES=${HOSTLIST}
ALTADDRESSES=${IPLIST}
# CA_ORG=$P_CA_ORG
CA_DN="/CN=An MQTT broker${CA_ORG}"
CACERT=${DIR}/ca
# CACERT=ca
# SERVER="${DIR}/${host}"
SERVER="${host}"
SERVER_DN="/CN=${host}$CA_ORG"
keybits=4096
openssl=$(which openssl)
MOSQUITTOUSER=${MOSQUITTOUSER:=$USER}
SUBJALTNAME=""
CNF=""

# Signature Algorithm. To find out which are supported by your
# version of OpenSSL, run `openssl dgst -help` and set your
# signature algorithm here. For example:
#
#	defaultmd="-sha256"
#
defaultmd="-sha256"

function maxdays() {
	nowyear=$(date +%Y)
	years=$(expr 2032 - $nowyear)
	days=$(expr $years '*' 365)

	echo $days
}

function getipaddresses() {
	/sbin/ifconfig |
		grep -v tunnel |
		sed -En '/inet6? /p' |
		sed -Ee 's/inet6? (addr:)?//' |
		awk '{print $1;}' |
		sed -e 's/[%/].*//' |
		egrep -v '(::1|127\.0\.0\.1)'	# omit loopback to add it later
}

function addresslist() {

	ALIST=""
	for a in $(getipaddresses); do
		ALIST="${ALIST}IP:$a,"
	done
	ALIST="${ALIST}IP:127.0.0.1,IP:::1,"

	for ip in $(echo ${ALTADDRESSES}); do
		ALIST="${ALIST}IP:${ip},"
	done
	for h in $(echo ${ALTHOSTNAMES}); do
		ALIST="${ALIST}DNS:$h,"
	done
	ALIST="${ALIST}DNS:${host},DNS:localhost"
	echo $ALIST

}

function generateCNFFile() {
	# There's no way to pass subjAltName on the CLI so
	# create a cnf file and use that.

	CNF=`mktemp /tmp/cacnf.XXXXXXXX` || { echo "$0: can't create temp file" >&2; exit 1; }
	sed -e 's/^.*%%% //' > $CNF <<\!ENDconfig
	%%% [ JPMextensions ]
	%%% basicConstraints        = critical,CA:false
	%%% nsCertType              = server
	%%% keyUsage                = nonRepudiation, digitalSignature, keyEncipherment
	%%% extendedKeyUsage        = serverAuth
	%%% nsComment               = "Broker Certificate"
	%%% subjectKeyIdentifier    = hash
	%%% authorityKeyIdentifier  = keyid,issuer:always
	%%% subjectAltName          = $ENV::SUBJALTNAME
	%%% # issuerAltName           = issuer:copy
	%%% ## nsCaRevocationUrl       = http://mqttitude.org/carev/
	%%% ## nsRevocationUrl         = http://mqttitude.org/carev/
	%%% certificatePolicies     = ia5org,@polsection
	%%% 
	%%% [polsection]
	%%% policyIdentifier	    = 1.3.5.8
	%%% CPS.1		    = "http://localhost"
	%%% userNotice.1	    = @notice
	%%% 
	%%% [notice]
	%%% explicitText            = "This CA is for a local MQTT broker installation only"
	%%% organization            = "kathevigs"
	%%% noticeNumbers           = 1

!ENDconfig

	SUBJALTNAME="$(addresslist)"
	export SUBJALTNAME		# Use environment. Because I can. ;-)
}

days=$(maxdays)

server_days=825	# https://support.apple.com/en-us/HT210176

# if [ -n "$CAKILLFILES" ]; then
# 	rm -f $CACERT.??? $SERVER.??? $CACERT.srl
# fi

echo "   ____    _      "
echo "  / ___|  / \     "
echo " | |     / _ \    "
echo " | |___ / ___ \   "
echo "  \____/_/   \_\  "
echo "                  "

if [ ! -f "$CACERT-cert.$P_CA_FORMAT" ]; then
	printf '\e[1;32m%-6s\e[m' "No $CACERT-cert.$P_CA_FORMAT, generating..."
	echo ""

	# Create un-encrypted (!) key
	if [[ $P_CA_FORMAT == "crt" ]]; then
		$openssl req -newkey rsa:${keybits} -x509 -nodes $defaultmd -days $days -extensions v3_ca -keyout "$CACERT-key.key" -out "$CACERT-cert.crt" -subj "${CA_DN}"
		#creating an encripted key
		# openssl genrsa -out $CACERT.key -aes256 -passout pass:"$P_CA_KEY" 4096
		echo "Created CA crt in $CACERT-cert.$P_CA_FORMAT and key in $CACERT-key.key"
		chmod 400 "$CACERT-cert.key"
	else
	    #another .pem by example
		# root certs 
		# openssl genrsa -out ca-key.pem 4096
		
		# step 1: generate key 
		openssl genrsa -out "$CACERT-key.pem" ${keybits}

		# step 2: generate server cert
		openssl req -new -x509 -nodes -days 1000 -key "$CACERT-key.pem" -out "$CACERT-cert.pem" -subj "${CA_DN}"
		

		# client certs
		# openssl req -newkey rsa:4096 -days 1000 -nodes -keyout client-key.pem -out client-req.pem
		# openssl x509 -req -in client-req.pem -days 1000 -CA ca-cert.pem -CAkey ca-key.pem -set_serial 01 -out client-cert.pem
		
		
		# step 3: convert .pem to .der
		openssl x509 -in "$CACERT-cert.pem" -out "$CACERT-cert.der" -outform DER	

		#openssl x509 -inform PEM -in root.pem -outform DER -out root.cer

		#luego a .cer para poderlo subir al arduino
		# step 4: convert .der to .cer
		openssl x509 -inform der -in "$CACERT-cert.der" -out "$CACERT-cert.cer"

		# step 5: delete .der
		# rm -f $CACERT.der
	fi	

	# openssl req -new -x509 -days 1826 -key $CACERT.key -out $CACERT.crt -passin pass:"$P_CA_KEY" -subj "$CA_ORG"	
	
	echo "Created CA certificate in $CACERT-cert.$P_CA_FORMAT"
	# $openssl x509 -in $CACERT.crt -nameopt multiline -subject -noout
	
	chmod 444 "$CACERT-cert.$P_CA_FORMAT"
	chown $MOSQUITTOUSER $CACERT-*.*

	printf '\e[1;33m%-6s\e[m' "Getting "$CACERT-cert.$P_CA_FORMAT" fingerprint"
	echo ""
	openssl x509 -in "$CACERT-cert.$P_CA_FORMAT" -noout -sha256 -fingerprint
	echo ""

	printf '\e[1;31m%-6s\e[m' "the CA-cert key is not encrypted, remember to save it!"	
	echo ""
else
	printf '\e[1;32m%-6s\e[m' "$CACERT-cert.$P_CA_FORMAT, OK..."
	echo ""	
fi

if [ $kind == 'server' ]; then
	echo "   ____                           "
	echo "  / ___|  ___ _ ____   _____ _ __ "
	echo "  \___ \ / _ \ '__\ \ / / _ \ '__|"
	echo "   ___) |  __/ |   \ V /  __/ |   "
	echo "  |____/ \___|_|    \_/ \___|_|   "
	echo "                                  "

	if [ ! -f "server_certs/$SERVER-key.key" -a $P_CA_FORMAT == 'crt' ] || [ ! -f "server_certs/$SERVER-key.pem" -a $P_CA_FORMAT == 'pem' ]; then
		printf '\e[1;32m%-6s\e[m' "No server_certs/$SERVER-key.$P_CA_FORMAT, generating..."
		echo ""

		if [[ $P_CA_FORMAT == "crt" ]]; then
			echo "--- Creating server key and signing request"
			$openssl genrsa -out $SERVER-key.key $keybits

			$openssl req -new $defaultmd \
				-key $SERVER.key \
				-out $SERVER.csr \
				-subj "${SERVER_DN}"
			# chmod 400 $SERVER.key
			chmod 775 $SERVER.key
			chown $MOSQUITTOUSER $SERVER.key

			sudo mv "$P_HOSTNAME.csr" "$P_HOSTNAME.key" server_certs/
			printf '\e[1;36m%-6s\e[m' "server_certs/$SERVER.key and server_certs/$P_HOSTNAME.csr, CREATED..."
			echo ""
		else
			echo "--- Creating server key.pem and req.pem ..."
			openssl req -newkey rsa:4096 -nodes -keyout $P_HOSTNAME-key.pem -out $P_HOSTNAME-req.pem -subj "${CA_DN}"
			chmod 775 $P_HOSTNAME-key.pem
			chown $MOSQUITTOUSER $P_HOSTNAME-*.pem
			
			# echo "--- Creating cert server and signing request"
			# openssl x509 -req -in $P_HOSTNAME-req.pem -days 1000 -CA ca-cert.pem -CAkey ca-key.pem -set_serial 01 -out $P_HOSTNAME-cert.pem

			sudo mv $P_HOSTNAME-*.pem server_certs/
			printf '\e[1;36m%-6s\e[m' "server_certs/$P_HOSTNAME-req.pem, server_certs/$P_HOSTNAME-key.pem, CREATED..."
			echo ""
		fi		
	else
		printf '\e[1;32m%-6s\e[m' "server_certs/$SERVER-key, OK..."
		echo ""
	fi
	
	if  [-f "server_certs/$SERVER.csr" -a ! -f "server_certs/$SERVER.crt" -a "$P_CA_FORMAT" == "crt" ]; 
		then
			printf '\e[1;32m%-6s\e[m' "server_certs/$SERVER.csr OK but No server_certs/$SERVER.crt, generating crt..."
			echo ""

			generateCNFFile

			echo "--- Creating and signing server certificate"
				
			$openssl x509 -req $defaultmd \
				-in server_certs/$P_HOSTNAME.csr \
				-CA $CACERT.crt \
				-CAkey $CACERT.key \
				-CAcreateserial \
				-CAserial "${DIR}/ca.srl" \
				-out $SERVER.crt \
				-days $server_days \
				-extfile ${CNF} \
				-extensions JPMextensions

			rm -f $CNF

			chmod 444 $SERVER.crt
			chown $MOSQUITTOUSER $SERVER.crt

			printf '\e[1;33m%-6s\e[m' "Getting $SERVER.crt fingerprint"
			echo ""
			openssl x509 -in $SERVER.crt -noout -sha256 -fingerprint
			echo ""

			sudo mv "$P_HOSTNAME.crt" server_certs/
			printf '\e[1;36m%-6s\e[m' "server_certs/$SERVER.crt, CREATED..."
			echo ""
	elif [-f "server_certs/$P_HOSTNAME-req.pem" -a ! -f "server_certs/$P_HOSTNAME-cert.pem" -a "$P_CA_FORMAT" == "pem" ]; 
		then	
			printf '\e[1;32m%-6s\e[m' "server_certs/$P_HOSTNAME-req.pem OK but No server_certs/$P_HOSTNAME-cert.pem, generating crt..."
			echo ""

			generateCNFFile		
								
			echo "--- Creating cert server and signing request .pem"
			$openssl x509 -req \
				-in server_certs/$P_HOSTNAME-req.pem \
				-CA $CACERT-cert.pem \
				-CAkey $CACERT-key.pem \
				-set_serial 01 \
				-out $SERVER-cert.pem \
				-days $server_days \
				-extfile ${CNF} \
				-extensions JPMextensions

			rm -f $CNF

			chmod 444 $SERVER-cert.pem
			chown $MOSQUITTOUSER $SERVER-cert.pem

			sudo mv $P_HOSTNAME-*.pem server_certs/
			printf '\e[1;36m%-6s\e[m' "server_certs/$P_HOSTNAME-cert.pem, CREATED..."
		else
			printf '\e[1;32m%-6s\e[m' "server_certs/$SERVER-cert OK, server_certs/$SERVER-req,OK..."
			echo ""
		fi
else
	echo "    ____ _ _            _   "
	echo "   / ___| (_) ___ _ __ | |_ "
	echo "  | |   | | |/ _ \ '_ \| __|"
	echo "  | |___| | |  __/ | | | |_ "
	echo "   \____|_|_|\___|_| |_|\__|"
	echo "                            "

	if [ ! -d "client_certs/$CLIENT" ]; then
		printf '\e[1;36m%-6s\e[m' "folder client_certs/$CLIENT does not exists, creating it..."
		echo ""
		mkdir client_certs/"$CLIENT"
	fi

	if [ ! -f "client_certs/$CLIENT/$CLIENT.key" ]; then
		printf '\e[1;32m%-6s\e[m' "No client_certs/$CLIENT/$CLIENT.key, generating..."
		echo ""

		echo "--- Creating client key and signing request"
		$openssl genrsa -out $CLIENT.key $keybits

		CNF=`mktemp /tmp/cacnf-req.XXXXXXXX` || { echo "$0: can't create temp file" >&2; exit 1; }
		# Mosquitto's use_identity_as_username takes the CN attribute
		# so we're populating that with the client's name
		sed -e 's/^.*%%% //' > $CNF <<!ENDClientconfigREQ
		%%% [ req ]
		%%% distinguished_name	= req_distinguished_name
		%%% prompt			= no
		%%% output_password		= secret
		%%% 
		%%% [ req_distinguished_name ]
		%%% # C                       = AR
		%%% # ST                      = CABA
		%%% # L                       = Buenos Aires Capital
		%%% # O                       = kathevigs
		%%% # OU                      = MQTT
		%%% # CN                      = Katherine Aguirre
		%%% CN                        = $CLIENT
		%%% # emailAddress            = $CLIENT
!ENDClientconfigREQ
		$openssl req -new $defaultmd -key $CLIENT.key -out $CLIENT.csr -config $CNF
		chmod 755 $CLIENT.key
		
		sudo mv "$CLIENT.key" "$CLIENT.csr" "client_certs/$CLIENT/"
		printf '\e[1;36m%-6s\e[m' "client_certs/$CLIENT/$CLIENT.crt, CREATED..."
		echo ""
	else
	  printf '\e[1;32m%-6s\e[m' "client_certs/$CLIENT/$CLIENT.key and client_certs/$CLIENT/$CLIENT.csr, OK..."
	  echo ""
	fi

	if [ -f "client_certs/$CLIENT/$CLIENT.csr" -a ! -f "client_certs/$CLIENT/$CLIENT.crt" ]; then

		printf '\e[1;32m%-6s\e[m' "client_certs/$CLIENT/$CLIENT.csr OK but No client_certs/$CLIENT/$CLIENT.crt, generating crt..."
		echo ""

		CNF=`mktemp /tmp/cacnf-cli.XXXXXXXX` || { echo "$0: can't create temp file" >&2; exit 1; }
		sed -e 's/^.*%%% //' > $CNF <<\!ENDClientconfig
		%%% [ JPMclientextensions ]
		%%% basicConstraints        = critical,CA:false
		%%% subjectAltName          = email:copy
		%%% nsCertType              = client,email
		%%% extendedKeyUsage        = clientAuth,emailProtection
		%%% keyUsage                = digitalSignature, keyEncipherment, keyAgreement
		%%% nsComment               = "Client Broker Certificate"
		%%% subjectKeyIdentifier    = hash
		%%% authorityKeyIdentifier  = keyid,issuer:always

!ENDClientconfig

		SUBJALTNAME="$(addresslist)"
		export SUBJALTNAME		# Use environment. Because I can. ;-)

		echo "--- Creating and signing client certificate"
		$openssl x509 -req $defaultmd \
			-in client_certs/$CLIENT/$CLIENT.csr \
			-CA $CACERT.crt \
			-CAkey $CACERT.key \
			-CAcreateserial \
			-CAserial "${DIR}/ca.srl" \
			-out $CLIENT.crt \
			-days $days \
			-extfile ${CNF} \
			-extensions JPMclientextensions			

		rm -f $CNF
		chmod 444 $CLIENT.crt

		printf '\e[1;33m%-6s\e[m' "Getting $CLIENT.crt fingerprint"
		echo ""
		openssl x509 -in $CLIENT.crt -noout -sha256 -fingerprint
		echo ""
		        
        mv $CLIENT.crt "client_certs/$CLIENT/"
		cp $CACERT.crt "client_certs/$CLIENT/"
		printf '\e[1;36m%-6s\e[m' "client_certs/$CLIENT/$CLIENT.crt, CREATED..."
		echo ""
	else
		printf '\e[1;32m%-6s\e[m' "client_certs/$CLIENT/$CLIENT.crt, OK..."
		echo ""
	fi
fi

