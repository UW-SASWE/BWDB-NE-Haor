set "root=cd /d D:\SASWMS_Shahryar\HaorStorage"
%root%

CALL C:\ProgramData\Anaconda2\Scripts\activate.bat

CALL C:\ProgramData\Anaconda2\python.exe D:\SASWMS_Shahryar\HaorStorage\Web\Download_Haor_from_server.py

cd D:\SASWMS_Shahryar\HaorStorage\BD_Lake_Volume_Mapper\for_redistribution_files_only
BD_Lake_Volume_Trapez_Mapper.exe sardata/SAR_Haors_

CALL C:\ProgramData\Anaconda2\python.exe D:\SASWMS_Shahryar\HaorStorage\Web\Upload_Haor_to_server.py
ECHO uploaded!
