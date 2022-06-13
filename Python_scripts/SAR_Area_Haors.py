import ee
import folium
#~ %tensorflow_version 2.x
#~ import tensorflow as tf
import numpy as np
import pandas as pd
from datetime import datetime as dt
# from StringIO import StringIO
import math, time
try:
    #~ ee.Authenticate()
    ee.Initialize()
except Exception as e:
  ee.Authenticate()
  ee.Initialize() 
# from ee_plugin import Map 
import datetime
import math,os,time

import pickle
import os.path
import io,sys
from googleapiclient.discovery import build
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
from googleapiclient.http import MediaIoBaseDownload
	
DEM = ee.Image("USGS/SRTMGL1_003")

l7Raw = ee.ImageCollection('LANDSAT/LE07/C01/T1')
l7TOA = ee.ImageCollection("LANDSAT/LE07/C01/T1_TOA")
res = ee.FeatureCollection("users/climateClass/grand_tempwork/GRanD_reservoirs_v1_1")
dams = ee.FeatureCollection("users/climateClass/grand_tempwork/GRanD_dams_v1_1")
asia_res = ee.FeatureCollection("users/climateClass/grand_tempwork/GRanD_asia_ds_buffer")
usa_ds_res = ee.FeatureCollection("users/climateClass/grand_tempwork/nhd_ds_buffer_filt")
res_usgs = ee.FeatureCollection("users/climateClass/grand_tempwork/GRanD_reservoirs_usgs_nonan")
s1 = ee.ImageCollection("COPERNICUS/S1_GRD")

ne_bd = ee.Geometry.Polygon([[[90.42864448393777, 24.908543492090704],
          [90.51434642638162, 24.23021252443603],
          [90.92500335539773, 23.656235335961178],
          [91.15502960051492, 23.653837456446542],
          [91.38535625304178, 24.051633600999917],
          [91.90514690245584, 24.312173229538068],
          [92.2242654022117, 24.620487117272614],
          [92.45922691191629, 24.942985900973305],
          [92.1568883117576, 25.123368679140967],
          [91.60988933409647, 25.178880377968145],
          [90.52091247405008, 25.189288436305866]]])


AREA_THRESHOLD = 0.75
# Initialize date range

i=-1 #35
edate =  datetime.datetime.now() + datetime.timedelta(days=i)   # # 
sdate = edate  + datetime.timedelta(days=-3)   ## CHANGE FOR MORE DAYS TO MOSAIC

print("Looking from {} to {}...".format(sdate.strftime("%Y-%m-%d"),edate.strftime("%Y-%m-%d")))

Date_End = ee.Date(edate)  #ee.Date(datttte()) 
Date_Start = ee.Date(sdate) # ee.Date('1987-01-01')
  
n_days = Date_End.difference(Date_Start,'day').round();
gap = -10     ## CHANGE FOR MORE DAYS TO MOSAIC
dates = ee.List.sequence(0,n_days, 1);   #only one day list
def make_datelist(n):
  return Date_Start.advance(n,'day') 

dates = dates.map(make_datelist);

for dt in dates.getInfo():
	print(ee.Date(dt.get('value')).format('Y-MM-dd').getInfo())

ROI = ne_bd  ##selres.geometry().buffer(buffDist)    # for upstream from GRanD

#//*******************  SENTINEL SAR 1 PROCESSING  ***********************************************************

# Threshold for look angle used to remove erroneous data at far edges of images
angle_threshold_1 = ee.Number(45.4);
angle_threshold_2 = ee.Number(31.66)

# Define focal median function
def focal_median(img):
  fm = img.focal_max(30, 'circle', 'meters')
  fm = fm.rename("Smooth")
  return img.addBands(fm)
  
def smoothing(img):
  # Define a boxcar or low-pass kernel.
  boxcar = ee.Kernel.circle(radius = 1, units = 'pixels', magnitude = 1)

  # Smooth the image by convolving with the boxcar kernel.
  smooth = img.convolve(boxcar);
  smooth = smooth.rename("Smooth")
  return img.addBands(smooth)

  
  
# Define masking function for removing erroneous pixels
def mask_by_angle(img):
  angle = img.select('angle');
  vv = img.select('VV');
  mask1 = angle.lt(angle_threshold_1);
  mask2 = angle.gt(angle_threshold_2);
  vv = vv.updateMask(mask1);
  return vv.updateMask(mask2);
  

def calcWaterPix(img):
  sum = img.reduceRegion(reducer=ee.Reducer.sum(), geometry=ROI, scale=10, maxPixels=1e13);
  return img.set("water_pixels", sum.get('Class'));

# Apply median calculation on moving date window. 
def  detectWaterSAR(d):
  end = ee.Date(d);
  start = ee.Date(d).advance(gap ,'day');
  date_range = ee.DateRange(start,end);
  
  S1 = s1\
    .filterDate(date_range)\
    .filterBounds(ROI)\
    .filter(ee.Filter.listContains('transmitterReceiverPolarisation', 'VV'))\
    .filter(ee.Filter.eq('instrumentMode', 'IW'))
  vv = S1.map(mask_by_angle)
  vv = vv.map(smoothing); #focal_median);
  vv_median = vv.select("Smooth").median();
   
  clas = vv_median.lt(-13);
  mask = vv_median.gt(-32);
  clas  = clas.mask(mask); 
  
  #~ median_class = clas.addBands(vv_median).rename(['Class','Median']).clip(ROI) 
  #~ waterSAR = median_class.lt(-13)
  #~ numwaterpix = calcWaterPix(median_class)
  #~ waterArea = ee.Number(numwaterpix.get('water_pixels'))
  #~ waterArea = waterArea.multiply(.0001) 
  #~ return [waterSAR,waterArea]		

  sardate=ee.Date(S1.first().get('system:time_end'))
  return clas.addBands(vv_median).rename(['Class','Median']).clip(ROI).set("system:time_start", ee.Date(S1.first().get('system:time_start')).format('Y-MM-dd'));

### Sentinel ###

#~ try: 
  
resSAR = ee.ImageCollection(dates.map(detectWaterSAR))
#~ resSAR = resSAR.map(calcWaterPix)
#~ wc = ee.Array(resSAR.aggregate_array('water_pixels'))
#~ wc = wc.multiply(0.0001)
#~ d = (resSAR.aggregate_array('system:time_start'))


#~ areas = np.column_stack((d.getInfo(), wc.getInfo())).tolist()


# #### Check fraction of area covered 
imgafter = resSAR.median().select("Median").lt(-13).clip(ROI)
water_area = ee.Number(imgafter.reduceRegion(reducer=ee.Reducer.sum(), geometry=ROI, scale=10, maxPixels=1e13).get('Median')).multiply(0.0001);
print('water_area',water_area.getInfo())
area_after = imgafter.reduceRegion(reducer=ee.Reducer.count(), geometry=ROI, scale=10, maxPixels=1e13);
print('after',area_after.getInfo())

zeroimg = ee.Image(0)
imgbefore = zeroimg.where(imgafter.lt(-13),ee.Image(1)).clip(ROI)
area_before = imgbefore.reduceRegion(reducer=ee.Reducer.count(), geometry=ROI, scale=10, maxPixels=1e13);
print('before',area_before.getInfo())

area_ratio = ee.Number(area_after.get('Median')).divide(area_before.get('constant'))
print('ratio',area_ratio.getInfo())


#### CHECK OF AREA_THRESHOLD
if(area_ratio.getInfo() < AREA_THRESHOLD):
  print('Not enough area covered by SAR, fraction covered: {}'.format(area_ratio.getInfo()))

else:
  print('Exporting processed SAR, fraction covered: {}'.format(area_ratio.getInfo()))

  with open('HaorArea_smooth.csv', 'a') as f:
      f.write("{},{}\n".format(edate.strftime("%Y-%m-%d"),water_area.getInfo()))


  ############################################################################################
  ### export to drive

  sarlist = resSAR.toList(resSAR.size().getInfo())


  sarexp = ee.Image(sarlist.get(i)).select('Median')

  latest_day = edate.strftime("%Y-%m-%d") #sarexp.get('system:time_start')).getInfo()
  print('--Latest day',latest_day)

  print('--Exporting SAR area map {} to Drive'.format(latest_day))

  task_config = {
    'fileNamePrefix': 'SAR_Haors_Smooth_'  + latest_day,
    'crs': 'EPSG:4326',
    'scale': 10,
    'maxPixels': 1e13,
    'fileFormat': 'GeoTIFF',
    'skipEmptyTiles': True,
    'region': ROI,
    'folder': 'HaorStorage_GEE_exports'
    }

  task = ee.batch.Export.image.toDrive(imgafter, str('sar-export'), **task_config)
  task.start()
  import time
  while task.active():
    time.sleep(30)
    print(task.status())



  ############################################################################################
  ####  Download fromDrive 


  day = latest_day
  print('Downloading',day)
  SCOPES = ['https://www.googleapis.com/auth/drive']

  creds = None

  if os.path.exists('token.pickle'):
	  with open('token.pickle', 'rb') as token:
		  creds = pickle.load(token)

  if not creds or not creds.valid:
	  if creds and creds.expired and creds.refresh_token:
		  creds.refresh(Request())
	  else:
		  flow = InstalledAppFlow.from_client_secrets_file('credentials_saswe.json', SCOPES)
		  creds = flow.run_local_server(port=0)
		  # Save the credentials for the next run
	  with open('token.pickle', 'wb') as token:
		  pickle.dump(creds, token)

  service = build('drive', 'v3', credentials=creds)


  folder_id = # PUT FOLDER ID HERE  ## <-saswe,    
  page_token = None
  while True:
	  response = service.files().list(q="mimeType='image/tiff' and parents in '{}'".format(folder_id),
										    spaces='drive',
										    fields='nextPageToken, files(id, name)',
										    pageToken=page_token).execute()
	  for file in response.get('files', []):
		  # Process change
		  #~ print(file)
		  if('SAR_Haors_Smooth_'+day in file.get('name')):
			  print('Found latest map: %s (%s)' % (file.get('name'), file.get('id')))
			  file_id = file.get('id')
			  file_nm = file.get('name')
	  page_token = response.get('nextPageToken', None)
	  if page_token is None:
		  break


  print('Downloading ',file_nm)
  request = service.files().get_media(fileId=file_id)
  fh = io.FileIO('Processed/'+file_nm,mode='wb')
  downloader = MediaIoBaseDownload(fh, request)
  done = False
  while done is False:
	  status, done = downloader.next_chunk()
	  print(status)
	  print ("Completed %d%%." % int(status.progress() * 100))

#~ except:
  #~ print('No SAR image for selected day')
  #~ S1av = s1\
    #~ .filterDate(ee.Date(edate  + datetime.timedelta(days=-10)), ee.Date(edate))\
    #~ .filterBounds(ROI)\
    #~ .filter(ee.Filter.listContains('transmitterReceiverPolarisation', 'VV'))\
    #~ .filter(ee.Filter.eq('instrumentMode', 'IW'))
    
  #~ print ('first Available SAR in last 10 days ',ee.Date(S1av.first().get('system:time_start')).format('Y-MM-dd').getInfo())
