#!/usr/bin/Rscript

require(raster)
require(foreach)
require(doSNOW)

calc_gcc = function(img,msk){
  m = raster(msk)
  
  error = try(raster(img,band=1))
	
  if (inherits(error, "try-error")){
  	return(NA)
  }
	 
  r = raster(img,band=1)
  g = raster(img,band=2)
  b = raster(img,band=3)
  
  r_m = mask(r,m,maskvalue=0)
  g_m = mask(g,m,maskvalue=0)
  b_m = mask(b,m,maskvalue=0)
  
  plot(g_m)
  
  red = cellStats(r_m,stat='mean')
  green = cellStats(g_m,stat='mean')
  blue = cellStats(b_m,stat='mean')
  brightness = red + green + blue
  
  gcc = green / brightness
  return(gcc)
}

# set working directory
setwd('/srv/ftp/phenocam/lint/')

# get a list of all the files to process
files = list.files('.',pattern='*.jpg')

# get a mask (binary, black is the selection)
# use imagej or other tools to create  your selection
# save as tiff
roi = '/data/Dropbox/Research_Projects/code_repository/bitbucket/phenopi/lint_mask1.tif'

# extract date / time components from the image files
year = sapply(strsplit(files,split='_'),'[[',2)
month = sapply(strsplit(files,split='_'),'[[',3)
day = sapply(strsplit(files,split='_'),'[[',4)
time = sapply(strsplit(files,split='_'),'[[',5)
time = sapply(strsplit(time,split='.jpg'),'[[',1)

# construct a date vector
date = strptime(paste(year,month,day,time,sep=":"),"%Y:%m:%d:%H%M%S")

# setup a cluster with 8 cpus, will depend on your system
# process all images in parallel
cluster = makeCluster(6, type = "SOCK")
registerDoSNOW(cluster)
  output = foreach(i=1:length(files),.combine=rbind,.packages="raster") %dopar% try(calc_gcc(files[i],roi))
stopCluster(cluster)

# write the raw output to file for later
write.table(data.frame(date,output),'/data/Dropbox/Research_Projects/code_repository/bitbucket/phenopi/phenopi_validation_data.csv',
            sep=',',
            row.names=F,
            col.names=T,
            quote=F)

test = read.table('/data/Dropbox/Research_Projects/code_repository/bitbucket/phenopi/phenopi_validation_data.csv',header=T,sep=',')
date = strptime(test$date,"%Y-%m-%d %H:%M:%S")
doy = as.numeric(format(date,"%j"))
hour = as.numeric(format(date,"%H"))

sel = which(hour > 9 & hour < 17)

# calculate the gcc 90 
gcc90 = by(test$output,INDICES = doy,FUN=function(x,...)quantile(x,0.9,na.rm=T))

# make an overview plot
#png('/data/Dropbox/Research_Projects/code_repository/bitbucket/phenopi/phenopi_validation.png',1000,500)
plot(doy[sel],test$output[sel],pch=20,ylab='gcc',xlab='day',ylim=c(0.33,0.48))
lines(unique(doy),gcc90,col='red',lwd=2)
#dev.off()


