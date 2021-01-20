#!/bin/bash

###############################################################################
#                                                                             # 
# Raspberry pi Wifi configuration script used to list all devices, reset to   #
# the default, validate wifi settings and set the final password and          #
# configuration files                                                         #
#                                                                             #
# Default configuration files are stored in: /home/pi/defaults                #
# The script should be installed in: /home/pi/bin                             #
#                                                                             #
# Usage:                                                                      #
# wifi.sh list - lists all accessible wifi points                             #
# wifi.sh reset - returns to default AP mode                                  #
# wifi.sh validate network passwd - tries to validate the password on a       #
# network                                                                     #
# wifi.sh set network passwd - tries to validate the password on a            #
# network                                                                     #
#                                                                             #
# written by Koen Hufkens / koen.hufkens@gmail.com                            #
#                                                                             #
###############################################################################

# 1. scan the wifi networks
if [[ $1 == "list" ]]; then
	sudo iwlist wlan0 scan > /tmp/networks.txt
fi

# 2. reset to AP mode
if [[ $1 == "reset" ]]; then

	# overwrite the wpa_supplicant with the AP version
	sudo cp -f wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant.conf

	# dhcp settings
	sudo cp -f isc-dhcp-server /etc/default/isc-dhcp-server
	sudo service isc-dhcp-server restart
	  
	sudo cp -f dhcpd.conf /etc/dhcp/dhcpd.conf 
	sudo service dhcpd restart

	# network interface settings
	sudo cp -f interfaces /etc/network/interfaces

	# access point settings
	sudo cp -f hostapd.conf /etc/hostapd/hostapd.conf
	sudo cp -f hostapd.daemon /etc/default/hostapd
	sudo hostapd -d /etc/hostapd/hostapd.conf &

	# reset the connection
	sudo service networking restart

# 3. check the password
elif [[ $1 == "validate" ]]; then

	if [ "$#" -ne 3 ]; then
	    echo "no network or password specified"
	fi

	# disable the dhcp or dns and other services
	sudo service isc-dhcp-server stop
	sudo service dhcpd stop

	# network interface settings
	sudo cp -f interfaces.noap /etc/network/interfaces

	# access point settings
	killall hostapd

	# if not other arguments are given throw an error
	sudo nano /etc/wpa_supplicant/wpa_supplicant.conf 

	# check the password, if ok, save password and set key
	network={
    		ssid="testing"
		psk="testingPassword"
		}

	# reset the connection
	sudo service networking restart

	# first test the connection to the google name server
	connection=`ping -q -W 1 -c 1 8.8.8.8 > /dev/null && echo ok || echo error`

	# If the connection is ok, save password and set state
	if [[ $connection == "ok" ]];then
		cat "valid" > /tmp/passwd.status.txt
	else
		cat "faulty" > /tmp/passwd.status.txt
	fi

	# reset the AP configuration
	sudo service isc-dhcp-server start
	sudo service dhcpd start
	sudo hostapd -d /etc/hostapd/hostapd.conf &

	# reset the connection
	sudo service networking restart

# 4. set the password
elif [[ $1 == "set" ]]; then
	
	# check parameters
	if [ "$#" -ne 3 ]; then
	    echo "no network or password specified"
	fi

	# if not other arguments are given throw an error
	
	# check the password, if ok, save password and set key

else
	echo "Bad input parameters"
fi

# exit
exit 0 
