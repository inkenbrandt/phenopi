#!/bin/bash

# install the mjpeg streamer
# for an active view of the camera

# clean up previous code, if rerunning install on crash etc.
# if they exist
rm -rf mjpg-streamer-code-182* > /dev/null 2>&1

# install necessary libraries
sudo apt-get -y install libjpeg8-dev imagemagick libv4l-dev
sudo ln -s /usr/include/linux/videodev2.h /usr/include/linux/videodev.h

# download the mjpeg streamer daemon
# and unzip the file
wget http://sourceforge.net/code-snapshots/svn/m/mj/mjpg-streamer/code/mjpg-streamer-code-182.zip

# unzip downloaded file
unzip mjpg-streamer-code-182.zip > /dev/null 2>&1

# enter the unzipped directory and compile the
# necessary parts
cd mjpg-streamer-code-182/mjpg-streamer
make mjpg_streamer input_file.so output_http.so > /dev/null 2>&1

# copy all parts to the necessary locations
sudo cp mjpg_streamer /usr/local/bin
sudo cp output_http.so input_file.so /usr/local/lib/
sudo cp -R www /usr/local/www

# clean up the compilation directory
cd ../../
rm -rf mjpg-streamer-code-182*

# move simple index.html in place
sudo mv -f /home/pi/phenopi/index.html /usr/local/www

# feedback
echo "installed the mjpeg streamer!"