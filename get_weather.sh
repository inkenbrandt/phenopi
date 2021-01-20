#!/bin/bash
 
function get_weather() {

	# first test the connection to a google dns server
	connection=`ping -q -W 1 -c 1 8.8.8.8 > /dev/null && echo ok || echo error`

	#if the connection is up, proceed
	if [[ $connection == "ok" ]];then

		# determine the pi's external ip address
		current_ip=$(curl -s ifconfig.co)

		# get geolocation data 
		geolocation_data=$(./mygeoip.py ${current_ip})
		
		# look up the location based upon the external ip
		latitude=$(echo ${geolocation_data} | awk '{print $1}')
		longitude=$(echo ${geolocation_data} | awk '{print $2}')

		# get the current weather for the current location
		# for some reason I can't split the lines, keep as is
		current_weather_data=$(curl -s "http://api.openweathermap.org/data/2.5/forecast/daily?lat=${latitude}&lon=${longitude}&cnt=1&mode=json&units=metric&appid=d0fd40b33fcecb1d0ae461686eaeddc1")

		# extract parameters from openweathermap.org station summary	
		w_latitude=$(echo $current_weather_data | grep -oP -i '(?<="lat":)[^\,]*'  | tr -d "[{}]" )
		
		w_longitude=$(echo $current_weather_data | grep -oP -i '(?<="lon":)[^\,]*' )

		temp_day=$(echo $current_weather_data | grep -oP -i '(?<="day":)[^\,]*' )

		temp_min=$(echo $current_weather_data | grep -oP -i '(?<="min":)[^\,]*' )

		temp_max=$(echo $current_weather_data | grep -oP -i '(?<="max":)[^\,]*' )
		
		humidity=$(echo $current_weather_data | grep -oP -i '(?<="humidity":)[^\,]*')

		visibility=$(echo $current_weather_data | grep -oP -i '(?<="description":)[^\,]*' | sed 's/"//g')

		clouds=$(echo $current_weather_data | grep -oP -i '(?<="clouds":)[^\,]*' | tr -d "[{}]")

		wind_speed=$(echo $current_weather_data | grep -oP -i '(?<="speed":)[^\,]*')

		pressure=$(echo $current_weather_data| grep -oP -i '(?<="pressure":)[^\,]*')

		# create weather string, to be put in EXIF data
		weather_string=$(echo "IP: ${current_ip},\
		 Lat_deg: ${latitude},\
		 Long_deg: ${longitude},\
		 Weather_Lat_deg: ${w_latitude},\
		 Weather_Long_deg: ${w_longitude},\
		 Temp_day_C: ${temp_day},\
		 Temp_min_C: ${temp_min},\
		 Temp_max_C: ${temp_max},\
		 Hum_%: ${humidity},\
		 Press_hPa: ${pressure},\
		 Wind_mps: ${wind_speed},\
		 Vis_char: ${visibility},\
		 Clouds_%: ${clouds}\
		 ")

		# return value
		echo $weather_string
	
	else
	
		# output empty string
		weather_string=$(echo "IP: NA,\
		 Lat_deg: NA,\
		 Long_deg: NA,\
		 Weather_Lat_deg: NA,\
		 Weather_Long_deg: NA,\
		 Temp_day_C: NA,\
		 Temp_min_C: NA,\
		 Temp_max_C: NA,\
		 Hum_%: NA,\
		 Press_hPa: NA,\
		 Wind_mps: NA,\
		 Vis_char: NA,\
		 Clouds_%: NA\
		 ")
	
		# return value
		echo $weather_string
	fi
}
