#!/bin/bash


cd /home/saswms/ShahryarWork/HaorStorage/

nn=1
i=$(date +"%Y" -d "$nn days ago")	 ## "today")			## Year
j=$(date +"%m" -d "$nn days ago")	 ## "today")			## Month
k=$(date +"%d" -d "$nn days ago")	 ##"today")			## Day
j=$((10#$j)) # converting to decimal form octal in case of 08 or 09
k=$((10#$k))

ym=$i$(printf %02d $j) #-$(printf %02d $k)
ymd=$i$(printf %02d $j)$(printf %02d $k)
echo $ymd
 
 
## after Matlab processing

## process png
cd /home/saswms/ShahryarWork/HaorStorage/Processed
#Here download the processed tif files from the saswe server using wget
gdaldem color-relief Processed_Haor_${ymd}.tif  ../water_binary_palette.txt -alpha cProcessed_Haor_${ymd}.tif
gdal_translate -of png cProcessed_Haor_${ymd}.tif Processed_Haor_${ymd}.png
gdal_translate -of png cProcessed_Haor_${ymd}.tif Processed_Haor.png     ## for latest day label

## send to server

#Here send the processed tif files back to saswe serve using wput
rm cProcessed_Haor_${ymd}.tif
