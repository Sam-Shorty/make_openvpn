#!/bin/bash

# A little script to create multiple OpenVPN servers that are totally independent of each other and their clients.
# Compatible with various linux distros.

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
    echo "Make sure you have OpenVPN and Easy-RSA installed on your system."
    exit 
fi

# Make sure OpenVPN and Easy-RSA is installed
CHECK_OPENVPN=`dpkg -s openvpn | grep Status | awk '{ print $4 }'`
if [ "$CHECK_OPENVPN" = "not-installed" ]
then
    echo "OpenVPN not installed"
    echo "Please install it with your packet manager and retry"
    exit
fi
CHECK_EASYRSA=`dpkg -s easy-rsa | grep Status | awk '{ print $4 }'`
if [ "$CHECK_EASYRSA" = "not-installed" ]
then
    echo "Easy-RSA not installed"
    echo "Please install it with your packet manager and retry"
    exit
fi

# Various variable
WORKING_DIRECTORY=${PWD}
SERVER_DIR=${PWD}/${1}

# Print variable in use and ask for confirm
echo -e "Using the following variable:"
echo "SERVER_DIR: ${SERVER_DIR}"
echo "IP: ${2}"
echo "PORT: ${3}"
echo "IP_POOL: ${4}/24"

while true; do
    read -p "Confirm the variable and continue with installation? Y/n: " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer Y/n.";;
    esac
done

# Create server directory
echo -e "\nCreating server directory..."
mkdir ${SERVER_DIR}

# All abount easy-rsa
echo -e "Creating easy-rsa infrastructure...\n"
mkdir ${SERVER_DIR}/easy-rsa
ln -s /usr/share/easy-rsa/* ${SERVER_DIR}/easy-rsa
cp ${WORKING_DIRECTORY}/conf/vars ${SERVER_DIR}/easy-rsa
cd ${SERVER_DIR}/easy-rsa
./easyrsa init-pki

echo -e "Building the CA...\n"
./easyrsa build-ca nopass

echo -e "Generating server request...\n"
./easyrsa gen-req server nopass

echo -e "Sign server req...\n"
./easyrsa sign-req server server

# Copy generated file
cd ${SERVER_DIR}
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
cp ${WORKING_DIRECTORY}/conf/server.conf server.conf
sed -i "s:{PORT}:${3}:g" server.conf
sed -i "s:{IP_POOL}:${4}:g" server.conf

# All about generating make-client.sh
echo -e "Creating clients..."
mkdir clients
cp ${WORKING_DIRECTORY}/conf/make-client.sh clients/
chmod 700 clients/make-client.sh
cp ${WORKING_DIRECTORY}/conf/client.conf clients/
sed -i "s:{IP}:${2}:g" clients/client.conf
sed -i "s:{PORT}:${3}:g" clients/client.conf

# Create other dir
echo -e "Creating ccd dir"
mkdir ccd
echo -e "Creating log dir"
mkdir log

# All about the service
echo -e "Creating service..."
cp ${WORKING_DIRECTORY}/conf/openvpn-base.service openvpn-${1}.service
sed -i "s:{NAME}:${1}:g" openvpn-${1}.service
sed -i "s:{SERVER_DIR}:${SERVER_DIR}:g" openvpn-${1}.service
sudo cp openvpn-${1}.service /lib/systemd/system/

echo -e "Enabling and starting the service...\n"
sudo systemctl enable openvpn-${1}.service
sudo systemctl start openvpn-${1}.service

# Open the port in ufw
while true; do
    read -p "Do you want to open port in ufw and restart it? Y/n: " yn
    case $yn in
        [Yy]* ) echo -e "Opening port in ufw and restart it...\n"
                sudo ufw allow ${3}/udp
                sudo ufw disable
                sudo ufw enable
        ;;
        [Nn]* ) break;;
        * ) echo "Please answer Y/n.";;
    esac
done

# Write log
cd ..
echo -e "${1} on IP: ${2}:${3} with pool: ${4}/24" >> vpnserver.log