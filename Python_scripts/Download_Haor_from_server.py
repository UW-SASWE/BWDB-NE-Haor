# -*- coding: utf-8 -*-
"""
Created on Mon May 25 19:46:35 2020

@author: fhossain
"""

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

    def download_SAR(self):
        text = urllib.URLopener()
        enddate = self.forestartdate 
        preciptime = (enddate + datetime.timedelta(days=-1)).strftime('%Y%m%d') 
        dwntime = (enddate + datetime.timedelta(days=-1)).strftime('%Y-%m-%d') 
        wrftime=enddate.strftime('%Y%m%d')
        # IMERG
        print "Downloading SAR: SAR_Haors_Smooth_" + dwntime + ".tif" 
        try:
            text.retrieve("http://128.95.45.89/haors/maps/SAR_Haors_Smooth_" + dwntime + ".tif" , "D:\SASWMS_Shahryar\HaorStorage\BD_Lake_Volume_Mapper\\for_redistribution_files_only\sardata\SAR_Haors_" + dwntime + ".tif" )
        except:
            print "SAR not available"
            

if __name__ == '__main__':
#    for nd in range(-2,-1):  #(-53,0):
    nd= 0 #0
    forecast = HaorStorageProcessor(nd)
    forecast.download_SAR()