#!/bin/bash

# First argument: Client name

# Argoument check
if [ $# -eq 0 ]
then 
    echo 'Invalid number of argoument'
    exit 
fi

# Setup variable
cd ..
SERVER_DIR=${PWD}
CLIENT_DIR=${PWD}/client-configs/${1}
BASE_CONFIG=${PWD}/client-configs/base.conf

echo -e "Using the following variable:"
echo -e "SERVER_DIR: ${SERVER_DIR}"
echo -e "CLIENT_DIR: ${CLIENT_DIR}"
echo -e "BASE_CONFIG: ${BASE_CONFIG}"

echo -e "Create client folder...\n"
mkdir ${CLIENT_DIR}

echo -e "Create client key and crt...\n"
cd ${SERVER_DIR}/easy-rsa
./easyrsa gen-req ${1} nopass
./easyrsa sign-req client ${1}

echo -e "Copy various file...\n"
cd ${SERVER_DIR}
cp easy-rsa/pki/issued/${1}.crt client-configs/${1}
cp easy-rsa/pki/private/${1}.key client-configs/${1}
cp ta.key client-configs/${1}
cp ca.crt client-configs/${1}

echo -e "Generate file in ccd...\n"
touch ccd/${1}

echo -e "Generating OVPN...\n"
cat ${BASE_CONFIG} \
    <(echo -e '<ca>') \
    ${CLIENT_DIR}/ca.crt \
    <(echo -e '</ca>\n<cert>') \
    ${CLIENT_DIR}/${1}.crt \
    <(echo -e '</cert>\n<key>') \
    ${CLIENT_DIR}/${1}.key \
    <(echo -e '</key>\n<tls-crypt>') \
    ${CLIENT_DIR}/ta.key \
    <(echo -e '</tls-crypt>') \
    > ${CLIENT_DIR}/${1}.ovpn