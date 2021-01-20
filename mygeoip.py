#!/usr/bin/python
# Tiny script that spits out the
# latitude and longitude for a given
# ip address using the geolite database

# load libraries
import sys
from geoip import geolite2

# if an argument is given, run it through lookup
# otherwise spit out NA
if len(sys.argv)==1:
	print "%s %s" % ("NA","NA")

else:
	# parse the first argument given to the function
	# which should be an ip address and run it through
	# the geoip lookup database
	try:
		match = geolite2.lookup(str(sys.argv[1]))
	
		# spit out the latitude and longitude for this ip
		# address, space separated
		print "%s %s" % match.location

	# catch value errors on badly formed ip addresses
	except ValueError:
		print "%s %s" % ("NA","NA")