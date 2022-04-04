#!/bin/bash

# First argument: VPN name
# Second argument: Server IP
# Third argument: Server port
# Fourth argument: IP pool address

# Argoument check
if [ $# -eq 0 ]
then 
    echo "Invalid number of argoument"
    exit 
fi

# Various variable
SERVER_DIR=${PWD}/${1}

echo -e "Using the following variable:\n"
echo "SERVER_DIR: ${SERVER_DIR}"
echo "IP: ${2}"
echo "PORT: ${3}"

echo -e "\nCreating server directory...\n"
mkdir ${SERVER_DIR}

echo -e "Creating easy-rsa infrastructure...\n"
mkdir ${SERVER_DIR}/easy-rsa
ln -s /usr/share/easy-rsa/* ${SERVER_DIR}/easy-rsa
cp /etc/openvpn/base-conf/vars ${SERVER_DIR}/easy-rsa
cd ${SERVER_DIR}/easy-rsa
./easyrsa init-pki

echo -e "Building the CA...\n"
./easyrsa build-ca nopass

echo -e "Generating server request...\n"
./easyrsa gen-req server nopass

echo -e "Importing and sign server req...\n"
./easyrsa import-req pki/reqs/server.req server
./easyrsa sign-req server server

echo -e "Generating ta.key...\n"
openvpn --genkey secret ta.key

echo -e "Copy various file...\n"
cp pki/private/server.key ${SERVER_DIR}
cp pki/issued/server.crt ${SERVER_DIR}
cp pki/ca.crt ${SERVER_DIR}
cp ta.key ${SERVER_DIR}

echo -e "Creating server.conf...\n"
cd ${SERVER_DIR}
cp /etc/openvpn/base-server/server.conf server.conf
sed -i "s/{PORT}/${3}/g" server.conf
sed -i "s/{IP_POOL}/${4}/g" server.conf

echo -e "Creating clients...\n"
mkdir clients
cp /etc/openvpn/base-server/make-client.sh clients
chmod 700 clients/make-client.sh
cp /etc/openvpn/base-server/base.conf clients
sed -i "s/{IP}/${2}/g" clients/base.conf
sed -i "s/{PORT}/${3}/g" clients/base.conf

echo -e "Creating ccd adn log dir...\n"
mkdir ccd
mkdir log

echo -e "Enabling and starting the service...\n"
sudo systemctl enable openvpn-spectra@${1}.service
sudo systemctl start openvpn-spectra@${1}.service

echo -e "Opening port in ufw and restart it...\n"
sudo ufw allow ${2}/udp
sudo ufw disable
sudo ufw enable