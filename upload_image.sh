#!/bin/bash
#
# This is the script to upload images.
#
# Written by: Koen Hufkens
# Contact: koen.hufkens@gmail.com
#
# credit goes to Istvan Szantai from which
# I adapted his bash_weather.sh code to create
# my own weather extraction routines.

# set home path
path="/home/pi"

# load the weather library
source $path/phenopi/get_weather.sh

# camera type
camera="PhenoPi"

# set site name
site=$( awk -v p=1 'NR==p' /home/pi/phenopi/config.txt)

# set privacy
privacy=$( awk -v p=2 'NR==p' /home/pi/phenopi/config.txt)

# grab the current time / date
# for the image name as well as the header
file_date=$(date +"%Y_%m_%d_%H%M%S")


# get time zone sign
sign=$(date +"%Z" | cut -c'4')

# convert the sign from the UTC time zone TZ variable (for plotting in overlay)
if [ "$sign" = "+" ]; then
        tzone=`date +"%Z" | sed 's/-/+/g'`
else
        tzone=`date +"%Z" | sed 's/+/-/g'`
fi

# format header
header_date=$(echo `date +"%a %b %d %Y %H:%M:%S"` $tzone)

# check if the output directory exists
# if not create it!
if [ ! -d $path/phenopi_images ]; then
  mkdir $path/phenopi_images
fi

# check if there is still space left to store pictures
# this is under the assumption that the camera keeps
# running for a long time without an internet connection
free_space=$(df -h | sed -n 2p | awk '{print $5}' | tr -d '%')

# if there isn't enough space left on the drive quit
# no picture will be saved
if [[ $free_space -ge 98 ]];then
		echo "Not enough space to buffer images!"
		exit 0
	else

	# grab an image from the camera
	# -vf / -hf are vertical and horizontal flip parameters
	raspistill -mm matrix \
	 -awb off \
	 -awbg 1.5,1.2 \
	 -w 1296 -h 972 \
	 -vf -hf \
	 -t 500 \
	 -x EXIF.WhiteBalance=1 \
	 -ex night \
	 -th none \
	 -o $path/tmp.jpg

	# set privacy mask (25 or 50 % of the image)
	if [[ "$privacy" == "25" ]]; then
		convert $path/tmp.jpg -fill blue -stroke blue -draw "rectangle 0,729 1296,972" tmp_private.jpg 
	elif [[ "$privacy" == "50" ]]; then
		convert $path/tmp.jpg -fill blue -stroke blue -draw "rectangle 0,486 1296,972" tmp_private.jpg 
	else
		cp $path/tmp.jpg $path/tmp_private.jpg
	fi

	# collect data for the image header, site, date, exposure, white balance
	label=$(echo ${site} - ${camera} - ${header_date})
	exposure=$(exif $path/tmp.jpg | grep "Exposure Time" | cut -d'|' -f2 )

	# create a header with the site description and exposure value
	convert -background blue -fill white \
		  -pointsize 24 label:"$label\nExposure: $exposure" \
		  $path/label.gif

	# paste the header on top of the original image (latest.jpg)
	composite -gravity northwest $path/label.gif $path/tmp_private.jpg $path/latest.jpg

	# get weather data
	weather_string=$(get_weather)

	# use exif rather than the raspistill code to fill up the 'Image Description' EXIF tag
	# results with raspistill vary / exif needs full paths in file input - output
	exif --output=$path/phenopi_images/${site}_${file_date}.jpg --ifd=0 --tag=0x010e --set-value="$weather_string" --no-fixup $path/latest.jpg

	# change permissions to read writable
	sudo chmod a+rw $path/phenopi_images/*.jpg

	# for debugging purposes copy latest image back into the home directory
	# if online no data will be saved on the device, safe for this image!
	cp $path/phenopi_images/${site}_${file_date}.jpg $path/latest.jpg
	sudo cp $path/latest.jpg /usr/local/www

	# remove temporary files
	rm $path/label.gif
	rm $path/tmp.jpg
	rm $path/tmp_private.jpg

	# first test the connection to the phenocam server
	connection=`ping -q -W 1 -c 1 phenocam.sr.unh.edu > /dev/null && echo ok || echo error`

	# If the connection is up, upload all images to the server (old and new)
	if [[ "$connection" == "ok" ]];then

		# move into the directory that holds all images
		cd $path/phenopi_images

		# move all images to the server, delete the images on success
		# we use lftp, this enables me to upload images in bulk and
		# in rsync fashion.
		# TODO: change to final phenocam server later
		#lftp ftp://anonymous:anonymous@klima.sr.unh.edu -e "mirror --verbose --reverse --Remove-source-files ./ ./phenocam ;quit"
		#lftp ftp://anonymous:anonymous@140.247.98.64 -e "mirror --verbose --reverse --Remove-source-files ./ ./phenocam ;quit"

	fi
fi

# exit the script
exit 0
