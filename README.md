# make_openvpn
A little script to make full and multiple OpenVPN server and relative client.

For work I had to create various VPNs for various clients all independent from them on the same machine, thinking that it could be useful to other users, I decided to adapt the script to be used by anyone who needed a similar solution.

# CREATE VPN SERVER

To create the VPN server you have to use the make_openvpn.sh script.

If you want to change the basic configurations with which the VPN server is created you can edit the server.conf file in the base-server folder. 

The script takes the following arguments as input:

VPN name: all the files necessary for the VPN to work will be placed in a folder with the name you indicate, including CA and a script to create certificates and .ovpn files related to the clients of this VPN.
Server IP: simply the IP on which you want to make your server available (assuming that of the machine where you start the script) or a domain that points to it.
Server port: Simply the port you want the server to listen on. Since this script was created to allow the creation of multiple VPNs on the same machine, it is recommended to use different ports for each use, perhaps different from the standard 1194.
IP pool: Currently this is not a true pool as the specification of the netmask is not supported. You will simply have to enter a network address whose mask will be /24 by default, for the same reason as the port these addresses must always be related to different networks.

Example: ./make-server test myip.com 1194 10.8.0.0

Run this script directly in the folder where it is installed and where you want the VPN to be created

# CREATE CLIENT

After the VPN has been created, the "clients" folder will be present in it. Inside this folder there are the basic config file for each client, the script for creating the .ovpn file and certificates relating to each client and a folder for each client created containing all the files relating to it. 

If you want to change the basic configurations with which clients are created you can edit the base.conf file in the base-server folder. This file will then be copied to the clients folder and can be modified to create clients related to a single VPN server. 

The only argument this script needs is the name you want to give the client

Example: ./make-client myname