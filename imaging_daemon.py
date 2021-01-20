#!/usr/bin/python

# load libraries
import RPi.GPIO as GPIO
from datetime import datetime
from subprocess import call
from time import sleep

# set gpio pins
GPIO.setmode(GPIO.BOARD)
GPIO.setup(16, GPIO.IN, pull_up_down = GPIO.PUD_UP)
GPIO.setup(12, GPIO.OUT)

# set sec
sec = 0

# setup a callback function to take a picture when
# the button is pressed
def timer(channel):
    global sec
    # waiting for button release
    sec = 0
    tmp = 0
    while (GPIO.input(16) == GPIO.LOW):
        # delay for debouncing
        sleep(0.2)
        tmp += 0.2
    # write temporary timer value
    # to global, this should bypass
    # intermediary values being visible
    sec = tmp

# intiate callback function
GPIO.add_event_detect(16, GPIO.FALLING, callback=timer(), bouncetime=200)

# set the image acquisition interval
# fixed at a half hourly rate
interval=[0,30]

# create infinite imaging loop!
# when not being triggered to take a picture
# or uploading one to the server, continuously
# stream data through the server for live viewing.
while True:

    # grap current time
    currentMinute = datetime.now().minute
    currentHour = datetime.now().hour
    if sec >= 5:
        
        # turn on led
        GPIO.output(12,GPIO.HIGH)

        # shutdown (no gpio cleanup needed)
        call("sudo shutdown -h now",shell=True)
        
    elif sec > 0 and sec < 5:

        # flash 5 times
        count=5        
        i=0
        while i <= count:
            GPIO.output(12,GPIO.HIGH)
            sleep(0.2)
            GPIO.output(12,GPIO.LOW)
            sleep(0.2)
            i+=1
              
        # take snapshot
        call("raspistill -o /home/pi/snapshots/picture_`date date +'%Y_%m_%d_%H%M%S'`.jpg",shell=True)
        
        # make readable and writable by all
        call("sudo chmod a+rw /home/pi/snapshots/*.jpg",shell=True)

        # reset timer
        sec = 0

    else:
        if any(s == currentMinute for s in interval) and currentHour < 22 and currentHour > 4 :
        
            # flash 10 times
            count=10        
            i=0
            while i <= count:
                GPIO.output(12,GPIO.HIGH)
                sleep(0.2)
                GPIO.output(12,GPIO.LOW)
                sleep(0.2)
                i+=1
    
            # upload a phenopi image
            call("/home/pi/phenopi/./upload_image.sh",shell=True)
        
            # wait a minute, otherwise we duplicate uploads
            sleep(60)
        else:
            # if no phenopi image is taken update the streaming
            # jpeg source
            call("raspistill -n -w 640 -h 480 -q 95 -t 500 -th none -o /tmp/pic.jpg > /dev/null 2>&1",shell=True)

    sleep(30)

# cleanup gpio pins
GPIO.cleanup()

