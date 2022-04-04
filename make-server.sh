#!/bin/bash

# First argument: VPN name
# Second argument: Server IP
# Third argument: Server port
# Fourth argument: IP pool address

# Argoument check
if [ $# -eq 0 ]
then 
    echo "make_openvpn script by sam.shorty"
    echo -e "\n"
    echo "Please use the following arguments:"
    echo "1 -> Name of the VPN"
    echo "2 -> IP of the VPN"
    echo "3 -> Port of the VPN"
    echo "4 -> IP of the pool address for the VPN"
    echo "Example: ./make_openvpn test myip.com 1194 10.8.0.0"
    echo -e "\n"
    echo "Run this script directly in the folder where it is installed and where you want the VPN to be created"
    exit 
fi

# Various variable
SERVER_DIR=${PWD}/${1}
WORKING_DIRECTORY=${PWD}

# Print variable in use and ask for confirm
echo -e "Using the following variable:"
echo "SERVER_DIR: ${SERVER_DIR}"
echo "IP: ${2}"
echo "PORT: ${3}"
echo "IP_POOL: ${4}/24"

# Create server directory
echo -e "\nCreating server directory..."
mkdir ${SERVER_DIR}

# All abount easy-rsa
echo -e "Creating easy-rsa infrastructure...\n"
mkdir ${SERVER_DIR}/easy-rsa
ln -s /usr/share/easy-rsa/* ${SERVER_DIR}/easy-rsa
cp ${WORKING_DIRECTORY}/base-server/vars ${SERVER_DIR}/easy-rsa
cd ${SERVER_DIR}/easy-rsa
./easyrsa init-pki

echo -e "Building the CA...\n"
./easyrsa build-ca nopass

echo -e "Generating server request...\n"
./easyrsa gen-req server nopass

echo -e "Sign server req...\n"
./easyrsa sign-req server server
cd ..

# Copy generated file
echo -e "Copy server.key from ${SERVER_DIR}/easy-rsa/pki/private/server.key to ${SERVER_DIR}"
cp easy-rsa/pki/private/server.key ${SERVER_DIR}
echo -e "Copy server.crt from ${SERVER_DIR}/easy-rsa/pki/issued/server.crt to ${SERVER_DIR}"
cp easy-rsa/pki/issued/server.crt ${SERVER_DIR}
echo -e "Copy ca.crt from ${SERVER_DIR}/easy-rsa/pki/ca.crt to ${SERVER_DIR}"
cp easy-rsa/pki/ca.crt ${SERVER_DIR}

# All about server configuration
echo -e "Generating ta.key...\n"
openvpn --genkey secret ta.key

echo -e "Creating server.conf..."
cd ${SERVER_DIR}
cp ${WORKING_DIRECTORY}/base-server/server.conf server.conf
sed -i "s:{PORT}:${3}:g" server.conf
sed -i "s:{IP_POOL}:${4}:g" server.conf

# All about generating make-client.sh
echo -e "Creating clients..."
mkdir clients
cp ${WORKING_DIRECTORY}/base-server/make-client.sh clients
chmod 700 clients/make-client.sh
cp ${WORKING_DIRECTORY}/base-server/base.conf clients
sed -i "s:{IP}:${2}:g" clients/base.conf
sed -i "s:{PORT}:${3}:g" clients/base.conf

# Create other dir
echo -e "Creating ccd dir"
mkdir ccd
echo -e "Creating log dir"
mkdir log

# All about the service
echo -e "Creating service..."
cd ${WORKING_DIRECTORY}
cp base-server/openvpn-base.service base-server/openvpn-${1}.service
sed -i "s:{NAME}:${1}:g" base-server/openvpn-${1}.service
sed -i "s:{SERVER_DIR}:${SERVER_DIR}:g" base-server/openvpn-${1}.service
sudo mv base-server/openvpn-${1}.service /lib/systemd/system/

echo -e "Enabling and starting the service...\n"
sudo systemctl enable openvpn-${1}.service
sudo systemctl start openvpn-${1}.service

# Open the port in ufw
echo -e "Opening port in ufw and restart it...\n"
sudo ufw allow ${3}/udp
sudo ufw disable
sudo ufw enable