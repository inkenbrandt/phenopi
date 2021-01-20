#!/bin/bash

# raspberry pi
# real time clock installation script
# run this script after the normal install routine
# as it reboots on success
# 
# requirements: an internet connection

# first test the connection to the google name server
connection=`ping -q -W 1 -c 1 8.8.8.8 > /dev/null && echo ok || echo error`

# If the connection is down, bail
if [[ $connection != "ok" ]];then
	echo "No internet connection, can't determine time zone!"
	echo "Please connect to the net first."
	exit 1
else

	# some feedback
	echo "We are online"

	# determine the pi's external ip address
	current_ip=$(curl -s ifconfig.me)

	# get geolocation data 
	geolocation_data=$(curl -s http://freegeoip.net/xml/${current_ip})

	# look up the location based upon the external ip
	latitude=$(echo ${geolocation_data} | \
		grep -o -P -i "(?<=<Latitude>).*(?=</Latitude>)")
	
	longitude=$(echo ${geolocation_data} | \
		grep -o -P -i "(?<=<Longitude>).*(?=</Longitude>)")

	# check if we have an internet connection
	timezone_data=$(curl -s http://www.earthtools.org/timezone/$latitude/$longitude)

	# grab the timezone offset from UTC (non daylight savings correction)
	time_offset=$(echo ${timezone_data} | \
		grep -o -P -i "(?<=<offset>).*(?=</offset>)")

	# grab the sign of the time_offset
	sign=`echo $time_offset | cut -c'1'`

	# swap the sign of the offset to 
	# convert the sign from the UTC time zone TZ variable (for plotting in overlay)
	if [ "$sign" == "+" ]; then
		tzone=`echo "$time_offset" | sed 's/+/-/g'`
	else
		tzone=`echo "$time_offset" | sed 's/-/+/g'`
	fi

	# some feedback
	echo "we are in time zone $tzone"

	# set the time zone, time will be set by the NTP server
	# if online
	`echo sudo ln -sf /usr/share/zoneinfo/Etc/GMT$tzone /etc/localtime`

	# install necessary packages
	sudo apt-get -y install i2c-tools > /dev/null 2>&1
	
	# remove the fake hw-clock
	sudo apt-get -y remove fake-hwclock > /dev/null 2>&1
	sudo update-rc.d fake-hwclock remove > /dev/null 2>&1

	# So check if the boot config is up to date,
	# if so continue to check if there is a RTC
	# if not update boot parameters and reboot

	# check boot config parameters
	i2c=`grep "dtparam=i2c_arm=on" /boot/config.txt | wc -l`
	rtc=`grep "dtoverlay=ds1307-rtc" /boot/config.txt | wc -l`

	if [[ $i2c == "0" && $rtc == "0" ]]; then
		# adjust config.txt
		sudo echo "dtparam=i2c1=on" >> /boot/config.txt
		sudo echo "dtparam=i2c_arm=on" >> /boot/config.txt
	fi

	i2c=`grep "i2c" /etc/modules | wc -l`
	rtc=`grep "rtc" /etc/modules | wc -l`

	if [[ $i2c == "0" && $rtc == "0" ]]; then
		# add modules to /etc/modules
		sudo echo "i2c-bcm2708" >> /etc/modules
		sudo echo "i2c-dev" >> /etc/modules
		sudo echo "rtc-ds1307" >> /etc/modules
	fi

fi

echo "Please reboot to complete the installation!"

exit 0









