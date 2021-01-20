These scripts were downloaded from BitBucket (https://bitbucket.org/khufkens/).  They were written by Koen Hufkens.

# PhenoPi

Code to create a low budget (window mounted) PhenoCam using a raspberry pi camera.

The current collection of scripts is rough around the edges and a work in progress.

In theory there would be 3 scripts to run. One overall script called install_phenopi.sh and two others called by it, mainly install\_mjpeg\_daemon.sh (image acquisition daemon and server) and install\_rtc.sh (real time clock install).

Currently I do not integrate the real time clock install as this is still rather unstable, the 'normal' install with an ntp software driven clock should work just fine although aestethics could be better.

## Installation

In your raspberry pi home directory (/home/pi) clone the project to your raspberry pi using the following command (with git installed)

	git clone https://khufkens@bitbucket.org/khufkens/phenopi.git

all files will be cloned into a directory called phenopi

## Use

To run the basic install using the following command

	sh /home/pi/phenopi/install_phenopi.sh site_name privacy_value
	
or

	./install_phenopi.sh site_name privacy_value

in the /home/pi/phenopi directory

with:

Parameter     | Description                    	
------------- | ------------------------------ 	
site_name	      | the name of the site (no spaces allowed)
privacy_value	      | How much of the bottom of the image in % do you want to see removed (0, 25 or 50 are accepted values, default is 0)


After the installation your camera should be up and running and you should be able to find a website displaying constantly updating image at

	http://IP:8080

## Notes

Make sure that your raspberry pi camera is enabled, a description on how to enable your camera is provided on [the raspberry pi site](https://www.raspberrypi.org/documentation/usage/camera/)


## TODO:

- RAM disk writes for temporary files (https://www.domoticz.com/wiki/Setting_up_a_RAM_drive_on_Raspberry_Pi)
- watchdog routines
- contemplate moving image upload routine to python
- installation framework 
- dynamic AP on install
- installation GUI using whiplash
- trap errors on faulty time (no NTP server / no connection)
- generate own image to flash to SD
