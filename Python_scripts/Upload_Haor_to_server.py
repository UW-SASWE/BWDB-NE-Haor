import datetime
import urllib
#import urllib2
import subprocess
# import requests
#import h5py
# import pandas as pd
import os
import shutil
#import numpy as np
# import rasterio
#import csv
import glob
import paramiko
from scp import SCPClient

homedir=r"D:\SASWMS_Shahryar\HaorStorage\Web"
class HaorStorageProcessor():
    def __init__(self,nd):
        self.todaydate = datetime.date.today()
        self.noforedays = 3
        self.swatstartdate = datetime.datetime.combine(datetime.date(2017,1,1), datetime.time(0,0))
        self.forestartdate =  datetime.datetime.combine(self.todaydate, datetime.time(0,0)) + datetime.timedelta(days=nd)  #-2
        
        self.foreenddate = self.forestartdate + datetime.timedelta(days=self.noforedays)
#        self.foreenddate = datetime.datetime.combine(self.todaydate, datetime.time(0,0)) + datetime.timedelta(days=self.noforedays)
        
#        self.imergprcpdate = datetime.datetime.combine(self.todaydate, datetime.time(0,0)) + datetime.timedelta(days=-1)
        self.rasstartdate = self.forestartdate + datetime.timedelta(days=-8)
        # self.visstartdate = self.forestartdate + datetime.timedelta(days=-21)
        
        # self.conn = sqlite3.connect('Insituwaterlevel.db')
        print self.todaydate, self.forestartdate, self.foreenddate

    def download_Precip(self,ftype):
        text = urllib.URLopener()
        enddate = self.forestartdate 
        preciptime = (enddate + datetime.timedelta(days=-1)).strftime('%Y%m%d') 
        dwntime = (enddate + datetime.timedelta(days=-1)).strftime('%Y-%mm-%dd') 
        wrftime=enddate.strftime('%Y%m%d')
        # IMERG
        print "Downloading SAR: SAR_Haors_" + dwntime + "tif" 
        try:
            text.retrieve("http://128.95.45.89/haors/maps/SAR_Haors_Smooth_" + dwntime + "tif" , "D:\SASWMS_Shahryar\HaorStorage\BD_Lake_Volume_Mapper\for_redistribution_files_only\sardata\SAR_Haors_" + dwntime + "tif" )
        except:
            print "SAR not available"

                
       
            
    def pushresultsFTP(self):
        
        from ftplib import FTP 
        import os
         
        os.chdir("D:/SASWMS_Shahryar/HaorStorage/")
        ftp = FTP()
        ftp.set_debuglevel(2)
        #Here Connect to the saswe host server using ftp
        # Here login to saswms using the ftp
    
        

        strdate = self.forestartdate.strftime("%Y%m%d")
        enddate = self.forestartdate 
        preciptime = (enddate + datetime.timedelta(days=-1)).strftime('%Y%m%d') #20180103.precip.houston.txt

#        
#        scp = SCPClient(ssh.get_transport())
           
  
        filepath = 'BD_Lake_Volume_Mapper/for_redistribution_files_only/outdata/Processed_Haor_'+preciptime+'.tif'
        serverpath = '/opt/lampp/htdocs/haors/maps/Processed_tif'
        try:
            ftp.cwd(serverpath)

            fp = open(filepath, 'rb')
            ftp.storbinary('STOR %s' % os.path.basename(filepath), fp, 1024)
            fp.close()
#                    scp.put(filepath, serverpath)
            print  "Success FTP: " + filepath
            
        except:
            print  "--Error FTP: " + filepath
#            continue
#                
  
        # timeseries
        filepath = 'BD_Lake_Volume_Mapper/for_redistribution_files_only/Output_HaorVolume.txt'
        serverpath = '/opt/lampp/htdocs/haors/'                
        try:
            ftp.cwd(serverpath)
            
            fp = open(filepath, 'rb')
            ftp.storbinary('STOR %s' % os.path.basename(filepath), fp, 1024)
            fp.close()
#                    scp.put(filepath, serverpath)
            print  "Success FTP: " + filepath
            
        except:
            print  "--Error FTP: " + filepath
#            continue
#              

    def createSSHClient(self, server, port, user, password):
        client = paramiko.SSHClient()
        client.load_system_host_keys()
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        client.connect(server, port, user, password)
        return client
           
        
if __name__ == '__main__':
#    for nd in range(-2,-1):  #(-53,0):
    nd= 0 #0
    forecast = HaorStorageProcessor(nd)
#    for ftype in ['GFS']:
#        forecast.download_Precip(ftype)
#        forecast.swatforcing('IMERG')
#        forecast.swatprecipprep(ftype)     
#        forecast.swatsimulation(ftype)
#        forecast.swatoutputprocessor(ftype)
#        forecast.rasbndgen(ftype)
#        forecast.rasplangen(ftype)
#        forecast.rassimulation(ftype)
#    forecast.mappreparation()
#    forecast.pushresults()
    forecast.pushresultsFTP()
