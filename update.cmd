@echo off

SETLOCAL ENABLEDELAYEDEXPANSION

SET IISLOGSFOLDER=C:\INETPUB\LOGS

REM ****************************************************************************
REM  Set the source directory for the distribution, by extracting it from a CD 
REM  command
REM ****************************************************************************
REM FOR /F "delims=" %%I IN ('ECHO %CD%') DO SET SOURCE=%%I
SET SOURCE=E:\SCHEDJOBS\PERFLOGS
ECHO Setting SOURCE to %SOURCE%

REM ****************************************************************************
REM  Need a version of the source variable with an extra esc character
REM ****************************************************************************
SET GRAPHSOURCE=%SOURCE::=\:%

REM ***************************************************************************
REM  Summarising Data from Eventlogs from last 5 minutes. 
REM ***************************************************************************
ECHO  - Collecting Data...
%SOURCE%\tools\logparser "select EventType, count(*) as num from Application where timeWritten > SUB(TO_LOCALTIME(SYSTEM_TIMESTAMP()), TIMESTAMP('0000-01-01 00:05', 'yyyy-MM-dd HH:mm')) group by EventType" -q -iCheckpoint:%SOURCE%\chkpts\app.lpc> %SOURCE%\AppSum.txt
%SOURCE%\tools\logparser "select EventType, count(*) as num from Security where timeWritten > SUB(TO_LOCALTIME(SYSTEM_TIMESTAMP()), TIMESTAMP('0000-01-01 00:05', 'yyyy-MM-dd HH:mm')) group by EventType" -q -iCheckpoint:%SOURCE%\chkpts\sec.lpc> %SOURCE%\SecSum.txt
%SOURCE%\tools\logparser "select EventType, count(*) as num from System where timeWritten > SUB(TO_LOCALTIME(SYSTEM_TIMESTAMP()), TIMESTAMP('0000-01-01 00:05', 'yyyy-MM-dd HH:mm')) group by EventType" -q -iCheckpoint:%SOURCE%\chkpts\sys.lpc> %SOURCE%\SysSum.txt

REM ***************************************************************************
REM  Summarising Data from WMI 
REM ***************************************************************************
cscript //nologo %SOURCE%\tools\GetWMICounters.vbs > %SOURCE%\WMIStats.txt


	REM ***************************************************************************
	REM  Summarising Data from IIS
	REM ***************************************************************************
	:IIS
	FOR /F "tokens=1-3 delims=/" %%A IN ('DATE /T') DO (
	 SET DAY=%%A
	 SET MONTH=%%B
	 SET YEAR=%%C
	 SET YEAR=!YEAR:~2,2!
	)

	echo %YEAR%%MONTH%%DAY% - %IISLOGSFOLDER%\*%YEAR%%MONTH%%DAY%.log
	
	%SOURCE%\tools\logparser -i:iisw3c "select count(*) as num from %IISLOGSFOLDER%\*ex%YEAR%%MONTH%%DAY%.log where time > SUB(SYSTEM_TIME(), TIMESTAMP('00:05', 'hh:mm')) and sc-status < 299" -recurse -iCheckpoint:%SOURCE%\chkpts\200s.lpc -q >%SOURCE%\200s.txt
	%SOURCE%\tools\logparser -i:iisw3c "select count(*) as num from %IISLOGSFOLDER%\*ex%YEAR%%MONTH%%DAY%.log where time > SUB(SYSTEM_TIME(), TIMESTAMP('00:05', 'hh:mm')) and sc-status between 300 and 399" -recurse -iCheckpoint:%SOURCE%\chkpts\300s.lpc -q >%SOURCE%\300s.txt
	%SOURCE%\tools\logparser -i:iisw3c "select count(*) as num from %IISLOGSFOLDER%\*ex%YEAR%%MONTH%%DAY%.log where time > SUB(SYSTEM_TIME(), TIMESTAMP('00:05', 'hh:mm')) and sc-status between 400 and 499" -recurse -iCheckpoint:%SOURCE%\chkpts\400s.lpc -q >%SOURCE%\400s.txt
	%SOURCE%\tools\logparser -i:iisw3c "select count(*) as num from %IISLOGSFOLDER%\*ex%YEAR%%MONTH%%DAY%.log where time > SUB(SYSTEM_TIME(), TIMESTAMP('00:05', 'hh:mm')) and sc-status > 499" -recurse -iCheckpoint:%SOURCE%\chkpts\500s.lpc -q >%SOURCE%\500s.txt
	

REM ***************************************************************************
REM Analyse IISStats 
REM ***************************************************************************
SET TWOHUNDREDS=0	
SET THREEHUNDREDS=0
SET FOURHUNDREDS=0
SET FIVEHUNDREDS=0
FOR /F "tokens=1" %%i IN (%SOURCE%\200s.txt) DO SET TWOHUNDREDS=%%i
FOR /F "tokens=1" %%i IN (%SOURCE%\300s.txt) DO SET THREEHUNDREDS=%%i
FOR /F "tokens=1" %%i IN (%SOURCE%\400s.txt) DO SET FOURHUNDREDS=%%i
FOR /F "tokens=1" %%i IN (%SOURCE%\500s.txt) DO SET FIVEHUNDREDS=%%i

ECHO %date% %time% - %TWOHUNDREDS%:%THREEHUNDREDS%:%FOURHUNDREDS%:%FIVEHUNDREDS% >> %source%\http.log

REM ***************************************************************************
REM Analyse WMIStats 
REM ***************************************************************************
SET BYTESIN=0
SET BYTESOUT=0
SET BYTESTOTAL=0
SET CPUPRIV=0
SET CPUUSER=0
SET CPUTOTAL=0
SET DRVCSPACE=0
SET DRVDSPACE=0
SET DRVESPACE=0
SET DSKAVGQTOTAL=0
SET DSKAVGQREAD=0
SET DSKAVGQWRITE=0
SET DSKAVGBYTESREAD=0
SET DSKAVGBYTESWRITE=0
SET MEMCOMMITTEDBYTES=0
SET MEMPAGESPERSEC=0
SET MEMAVAILMBYTES=0
FOR /F "DELIMS=: tokens=1-5" %%i IN (%SOURCE%\WMISTATS.TXT) DO (
 IF %%i==Network SET BYTESIN=%%j
 IF %%i==Network SET BYTESOUT=%%k
 IF %%i==Network SET BYTESTOTAL=%%l
 IF %%i==CPU SET CPUPRIV=%%j
 IF %%i==CPU SET CPUUSER=%%k
 IF %%i==CPU SET CPUPRIV=%%l
 IF %%i==DiskSpace SET DRVCSPACE=%%j
 IF %%i==DiskSpace SET DRVDSPACE=%%k
 IF %%i==DiskSpace SET DRVESPACE=%%l
 IF %%i==DiskUsage SET DSKAVGQTOTAL=%%j
 IF %%i==DiskUsage SET DSKAVGQREAD=%%k
 IF %%i==DiskUsage SET DSKAVGQWRITE=%%l
 IF %%i==DiskUsage SET DSKAVGBYTESREAD=%%m
 IF %%i==DiskUsage SET DSKAVGBYTESWRITE=%%k
 IF %%i==MemoryUsage SET MEMCOMMITTEDBYTES=%%j
 IF %%i==MemoryUsage SET MEMPAGESPERSEC=%%k
 IF %%i==MemoryUsage SET MEMAVAILMBYTES=%%l
)
ECHO %BYTESIN%:%BYTESOUT%:%BYTESTOTAL% >%SOURCE%\log.txt
ECHO %CPUPRIV%:%CPUUSER%:%CPUTOTAL% >>%SOURCE%\log.txt
ECHO %DRVCSPACE%:%DRVDSPACE%:%DRVESPACE% >>%SOURCE%\log.txt
ECHO %DSKAVGQTOTAL%:%DSKAVGQREAD%:%DSKAVGQWRITE%:%DSKAVGBYTESREAD%:%DSKAVGBYTESWRITE% >>%SOURCE%\log.txt
ECHO %MEMCOMMITTEDBYTES%:%MEMPAGESPERSEC%:%MEMAVAILMBYTES% >>%SOURCE%\log.txt

REM ***************************************************************************
REM Analyse AppSum, stick data into Variables so that we can make use of them 
REM Later
REM ***************************************************************************
SET APPINFO=0
SET APPWARN=0
SET APPERR=0
SET APPAUDITFAIL=0
SET APPAUDITSUCCESS=0
SET APPSUCCESS=0
FOR /F "tokens=1,2" %%i in (%SOURCE%\appsum.txt) DO (
  IF %%i==0 SET APPSUCCESS=%%j
  IF %%i==1 SET APPERR=%%j
  IF %%i==2 SET APPWARN=%%j
  IF %%i==4 SET APPINFO=%%j
  IF %%i==8 SET APPAUDITSUCCESS=%%j
  IF %%i==16 SET APPAUDITFAIL=%%j
)

ECHO %APPSUCCESS%:%APPERR%:%APPWARN%:%APPINFO%:%APPAUDITSUCCESS%:%APPAUDITFAIL% >>%SOURCE%\log.txt

REM ***************************************************************************
REM Analyse SecSum, stick data into Variables so that we can make use of them 
REM Later
REM ***************************************************************************
SET SecINFO=0
SET SecWARN=0
SET SecERR=0
SET SecAUDITFAIL=0
SET SecAUDITSUCCESS=0
SET SecSUCCESS=0
FOR /F "tokens=1,2" %%i in (%SOURCE%\Secsum.txt) DO (
  IF %%i==0 SET SecSUCCESS=%%j
  IF %%i==1 SET SecERR=%%j
  IF %%i==2 SET SecWARN=%%j
  IF %%i==4 SET SecINFO=%%j
  IF %%i==8 SET SecAUDITSUCCESS=%%j
  IF %%i==16 SET SecAUDITFAIL=%%j
)
ECHO %SecSUCCESS%:%SecERR%:%SecWARN%:%SecINFO%:%SecAUDITSUCCESS%:%SecAUDITFAIL% >>%SOURCE%\log.txt

REM ***************************************************************************
REM Analyse SysSum, stick data into Variables so that we can make use of them 
REM Later
REM ***************************************************************************
SET SysINFO=0
SET SysWARN=0
SET SysERR=0
SET SysAUDITFAIL=0
SET SysAUDITSUCCESS=0
SET SysSUCCESS=0
FOR /F "tokens=1,2" %%i in (%SOURCE%\Syssum.txt) DO (
  IF %%i==0 SET SysSUCCESS=%%j
  IF %%i==1 SET SysERR=%%j
  IF %%i==2 SET SysWARN=%%j
  IF %%i==4 SET SysINFO=%%j
  IF %%i==8 SET SysAUDITSUCCESS=%%j
  IF %%i==16 SET SysAUDITFAIL=%%j
)
ECHO %SysSUCCESS%:%SysERR%:%SysWARN%:%SysINFO%:%SysAUDITSUCCESS%:%SysAUDITFAIL% >>%SOURCE%\log.txt

REM ***************************************************************************
REM Update event log rrd's
REM ***************************************************************************
ECHO  - Updating Rrds ...
%SOURCE%\tools\rrdtool.exe update %SOURCE%\rrds\AppEvents.rrd N:%APPSUCCESS%:%APPERR%:%APPWARN%:%APPINFO%:%APPAUDITSUCCESS%:%APPAUDITFAIL%
%SOURCE%\tools\rrdtool.exe update %SOURCE%\rrds\SecEvents.rrd N:%SecSUCCESS%:%SecERR%:%SecWARN%:%SecINFO%:%SecAUDITSUCCESS%:%SecAUDITFAIL%
%SOURCE%\tools\rrdtool.exe update %SOURCE%\rrds\SysEvents.rrd N:%SysSUCCESS%:%SysERR%:%SysWARN%:%SysINFO%:%SysAUDITSUCCESS%:%SysAUDITFAIL%

REM ***************************************************************************
REM Update Network log rrd's
REM ***************************************************************************
%SOURCE%\tools\rrdtool.exe update %SOURCE%\rrds\Network.rrd N:%BYTESIN%:%BYTESOUT%:%BYTESTOTAL%

REM ***************************************************************************
REM Update CPU log rrd's
REM ***************************************************************************
%SOURCE%\tools\rrdtool.exe update %SOURCE%\rrds\CPU.rrd N:%CPUPRIV%:%CPUUSER%:%CPUTOTAL%

REM ***************************************************************************
REM Update DiskSpace log rrd's
REM ***************************************************************************
%SOURCE%\tools\rrdtool.exe update %SOURCE%\rrds\DriveSpace.rrd N:%DRVCSPACE%:%DRVDSPACE%:%DRVESPACE% 

REM ***************************************************************************
REM Update DiskUsage log rrd's
REM ***************************************************************************
%SOURCE%\tools\rrdtool.exe update %SOURCE%\rrds\DriveUsage.rrd N:%DSKAVGQTOTAL%:%DSKAVGQREAD%:%DSKAVGQWRITE%:%DSKAVGBYTESREAD%:%DSKAVGBYTESWRITE%

REM ***************************************************************************
REM Update MemoryUsage log rrd's
REM ***************************************************************************
%SOURCE%\tools\rrdtool.exe update %SOURCE%\rrds\Memory.rrd N:%MEMCOMMITTEDBYTES%:%MEMPAGESPERSEC%:%MEMAVAILMBYTES%


REM ***************************************************************************
REM Update MemoryUsage log rrd's
REM ***************************************************************************
%SOURCE%\tools\rrdtool.exe update %SOURCE%\rrds\IIS.rrd N:%TWOHUNDREDS%:%THREEHUNDREDS%:%FOURHUNDREDS%:%FIVEHUNDREDS%



REM ***************************************************************************
REM Draw MemoryUsage log graphs
REM ***************************************************************************
ECHO  - Drawing Graphs ...
%SOURCE%\tools\rrdtool.exe graph %SOURCE%\pngs\dailies\AppEvents.png --start -86400 -E^
 DEF:AppInfo=%GRAPHSOURCE%\rrds\AppEvents.rrd:AppInfo:AVERAGE^
 DEF:AppWarn=%GRAPHSOURCE%\rrds\AppEvents.rrd:AppWarn:AVERAGE^
 DEF:AppErr=%GRAPHSOURCE%\rrds\AppEvents.rrd:AppErr:AVERAGE^
 DEF:AppAuditFail=%GRAPHSOURCE%\rrds\AppEvents.rrd:AppAuditFail:AVERAGE^
 DEF:AppAuditSuccess=%GRAPHSOURCE%\rrds\AppEvents.rrd:AppAuditSuccess:AVERAGE^
 DEF:AppSuccess=%GRAPHSOURCE%\rrds\AppEvents.rrd:AppSuccess:AVERAGE^
 AREA:AppInfo#0000FF88:Infos^
 LINE1:AppWarn#FCB514:Warning^
 LINE1:AppErr#FF0000:Errors^
 LINE1:AppAuditFail#551A8B:AuditFailures^
 LINE1:AppAuditSuccess#8B1C62:AuditSuccess^
 LINE1:AppSuccess#00FF00:Success

%SOURCE%\tools\rrdtool.exe graph %SOURCE%\pngs\dailies\SysEvents.png --start -86400 -E^
 DEF:SysInfo=%GRAPHSOURCE%\rrds\SysEvents.rrd:SysInfo:AVERAGE^
 DEF:SysWarn=%GRAPHSOURCE%\rrds\SysEvents.rrd:SysWarn:AVERAGE^
 DEF:SysErr=%GRAPHSOURCE%\rrds\SysEvents.rrd:SysErr:AVERAGE^
 DEF:SysAuditFail=%GRAPHSOURCE%\rrds\SysEvents.rrd:SysAuditFail:AVERAGE^
 DEF:SysAuditSuccess=%GRAPHSOURCE%\rrds\SysEvents.rrd:SysAuditSuccess:AVERAGE^
 DEF:SysSuccess=%GRAPHSOURCE%\rrds\SysEvents.rrd:SysSuccess:AVERAGE^
 AREA:SysInfo#0000FF88:Infos^
 LINE1:SysWarn#FCB514:Warning^
 LINE1:SysErr#FF0000:Errors^
 LINE1:SysAuditFail#551A8B:AuditFailures^
 LINE1:SysAuditSuccess#8B1C62:AuditSuccess^
 LINE1:SysSuccess#00FF00:Success

%SOURCE%\tools\rrdtool.exe graph %SOURCE%\pngs\dailies\SecEvents.png --start -86400 -E^
 DEF:SecInfo=%GRAPHSOURCE%\rrds\SecEvents.rrd:SecInfo:AVERAGE^
 DEF:SecWarn=%GRAPHSOURCE%\rrds\SecEvents.rrd:SecWarn:AVERAGE^
 DEF:SecErr=%GRAPHSOURCE%\rrds\SecEvents.rrd:SecErr:AVERAGE^
 DEF:SecAuditFail=%GRAPHSOURCE%\rrds\SecEvents.rrd:SecAuditFail:AVERAGE^
 DEF:SecAuditSuccess=%GRAPHSOURCE%\rrds\SecEvents.rrd:SecAuditSuccess:AVERAGE^
 DEF:SecSuccess=%GRAPHSOURCE%\rrds\SecEvents.rrd:SecSuccess:AVERAGE^
 AREA:SecInfo#0000FF88:Infos^
 LINE1:SecWarn#FCB514:Warning^
 LINE1:SecErr#FF0000:Errors^
 LINE1:SecAuditFail#551A8B:AuditFailures^
 LINE1:SecAuditSuccess#8B1C62:AuditSuccess^
 LINE1:SecSuccess#00FF00:Success

 %SOURCE%\tools\rrdtool.exe graph %SOURCE%\pngs\dailies\Network.png --start -86400 -E^
 DEF:BytesIn=%GRAPHSOURCE%\rrds\Network.rrd:BytesIn:AVERAGE^
 DEF:BytesOut=%GRAPHSOURCE%\rrds\Network.rrd:BytesOut:AVERAGE^
 DEF:BytesTotal=%GRAPHSOURCE%\rrds\Network.rrd:BytesTotal:AVERAGE^
 LINE1:BytesIn#0000FF88:BytesIn^
 LINE1:BytesOut#FCB514:BytesOut^
 LINE1:BytesTotal#00FF00:BytesTotal

%SOURCE%\tools\rrdtool.exe graph %SOURCE%\pngs\dailies\CPU.png --start -86400 -E^
 DEF:CpuPriv=%GRAPHSOURCE%\rrds\CPU.rrd:CpuPriv:AVERAGE^
 DEF:CpuUser=%GRAPHSOURCE%\rrds\CPU.rrd:CpuUser:AVERAGE^
 DEF:CpuTotal=%GRAPHSOURCE%\rrds\CPU.rrd:CpuTotal:AVERAGE^
 LINE1:CpuPriv#0000FF88:CpuPriv^
 LINE1:CpuUser#FCB514:CpuUser^
 LINE1:CpuTotal#FF0000:CpuTotal


%SOURCE%\tools\rrdtool.exe graph %SOURCE%\pngs\dailies\DiskUsage.png --start -86400 -E^
 DEF:DiskAvgQ=%GRAPHSOURCE%\rrds\DriveUsage.rrd:DiskAvgQ:AVERAGE^
 DEF:DiskAvgQRead=%GRAPHSOURCE%\rrds\DriveUsage.rrd:DiskAvgQRead:AVERAGE^
 DEF:DiskAvgQWrite=%GRAPHSOURCE%\rrds\DriveUsage.rrd:DiskAvgQWrite:AVERAGE^
 DEF:DiskAvgBytesRead=%GRAPHSOURCE%\rrds\DriveUsage.rrd:DiskAvgBytesRead:AVERAGE^
 DEF:DiskAvgBytesWrite=%GRAPHSOURCE%\rrds\DriveUsage.rrd:DiskAvgBytesWrite:AVERAGE^
 LINE1:DiskAvgQ#0000FF88:DiskAvgQ^
 LINE1:DiskAvgQRead#FCB514:DiskAvgQRead^
 LINE1:DiskAvgQWrite#551A8B:DiskAvgQWrite^
 LINE1:DiskAvgBytesRead#8B1C62:DiskAvgBytesWrite^
 LINE1:DiskAvgBytesWrite#FF0000:DiskAvgBytesWrite

%SOURCE%\tools\rrdtool.exe graph %SOURCE%\pngs\dailies\DriveSpace.png --start -86400 -E^
 DEF:DrvCSpace=%GRAPHSOURCE%\rrds\DriveSpace.rrd:DrvCSpace:AVERAGE^
 DEF:DrvDSpace=%GRAPHSOURCE%\rrds\DriveSpace.rrd:DrvDSpace:AVERAGE^
 DEF:DrvESpace=%GRAPHSOURCE%\rrds\DriveSpace.rrd:DrvESpace:AVERAGE^
 LINE1:DrvCSpace#0000FF88:DrvCSpace^
 LINE1:DrvDSpace#FCB514:DrvDSpace^
 LINE1:DrvESpace#FF0000:DrvESpace

%SOURCE%\tools\rrdtool.exe graph %SOURCE%\pngs\dailies\Memory.png --start -86400 -E^
 DEF:MemCommittedBytes=%GRAPHSOURCE%\rrds\Memory.rrd:MemCommittedBytes:AVERAGE^
 DEF:MemPagesPerSec=%GRAPHSOURCE%\rrds\Memory.rrd:MemPagesPerSec:AVERAGE^
 DEF:MemAvailMBytes=%GRAPHSOURCE%\rrds\Memory.rrd:MemAvailMBytes:AVERAGE^
 LINE1:MemCommittedBytes#0000FF88:MemCommittedBytes^
 LINE1:MemPagesPerSec#FCB514:MemPagesPerSec^
 LINE1:MemAvailMBytes#FF0000:MemAvailMBytes

 %SOURCE%\tools\rrdtool.exe graph %SOURCE%\pngs\dailies\IIS.png --start -86400 -E^
 DEF:Twos=%GRAPHSOURCE%\rrds\IIS.rrd:Twos:AVERAGE^
 DEF:Threes=%GRAPHSOURCE%\rrds\IIS.rrd:Threes:AVERAGE^
 DEF:Fours=%GRAPHSOURCE%\rrds\IIS.rrd:Fours:AVERAGE^
 DEF:Fives=%GRAPHSOURCE%\rrds\IIS.rrd:Fives:AVERAGE^
 LINE1:Twos#0000FF88:Twos^
 LINE1:Threes#FCB514:Threes^
 LINE1:Fours#8B1C62:Fours^
 LINE1:Fives#FF0000:Fives
 
 %SOURCE%\tools\rrdtool.exe graph %SOURCE%\pngs\weeklies\AppEvents.png --start -1w -E^
 DEF:AppInfo=%GRAPHSOURCE%\rrds\AppEvents.rrd:AppInfo:AVERAGE^
 DEF:AppWarn=%GRAPHSOURCE%\rrds\AppEvents.rrd:AppWarn:AVERAGE^
 DEF:AppErr=%GRAPHSOURCE%\rrds\AppEvents.rrd:AppErr:AVERAGE^
 DEF:AppAuditFail=%GRAPHSOURCE%\rrds\AppEvents.rrd:AppAuditFail:AVERAGE^
 DEF:AppAuditSuccess=%GRAPHSOURCE%\rrds\AppEvents.rrd:AppAuditSuccess:AVERAGE^
 DEF:AppSuccess=%GRAPHSOURCE%\rrds\AppEvents.rrd:AppSuccess:AVERAGE^
 AREA:AppInfo#0000FF88:Infos^
 LINE1:AppWarn#FCB514:Warning^
 LINE1:AppErr#FF0000:Errors^
 LINE1:AppAuditFail#551A8B:AuditFailures^
 LINE1:AppAuditSuccess#8B1C62:AuditSuccess^
 LINE1:AppSuccess#00FF00:Success

%SOURCE%\tools\rrdtool.exe graph %SOURCE%\pngs\weeklies\SysEvents.png --start -1w -E^
 DEF:SysInfo=%GRAPHSOURCE%\rrds\SysEvents.rrd:SysInfo:AVERAGE^
 DEF:SysWarn=%GRAPHSOURCE%\rrds\SysEvents.rrd:SysWarn:AVERAGE^
 DEF:SysErr=%GRAPHSOURCE%\rrds\SysEvents.rrd:SysErr:AVERAGE^
 DEF:SysAuditFail=%GRAPHSOURCE%\rrds\SysEvents.rrd:SysAuditFail:AVERAGE^
 DEF:SysAuditSuccess=%GRAPHSOURCE%\rrds\SysEvents.rrd:SysAuditSuccess:AVERAGE^
 DEF:SysSuccess=%GRAPHSOURCE%\rrds\SysEvents.rrd:SysSuccess:AVERAGE^
 AREA:SysInfo#0000FF88:Infos^
 LINE1:SysWarn#FCB514:Warning^
 LINE1:SysErr#FF0000:Errors^
 LINE1:SysAuditFail#551A8B:AuditFailures^
 LINE1:SysAuditSuccess#8B1C62:AuditSuccess^
 LINE1:SysSuccess#00FF00:Success

%SOURCE%\tools\rrdtool.exe graph %SOURCE%\pngs\weeklies\SecEvents.png --start -1w -E^
 DEF:SecInfo=%GRAPHSOURCE%\rrds\SecEvents.rrd:SecInfo:AVERAGE^
 DEF:SecWarn=%GRAPHSOURCE%\rrds\SecEvents.rrd:SecWarn:AVERAGE^
 DEF:SecErr=%GRAPHSOURCE%\rrds\SecEvents.rrd:SecErr:AVERAGE^
 DEF:SecAuditFail=%GRAPHSOURCE%\rrds\SecEvents.rrd:SecAuditFail:AVERAGE^
 DEF:SecAuditSuccess=%GRAPHSOURCE%\rrds\SecEvents.rrd:SecAuditSuccess:AVERAGE^
 DEF:SecSuccess=%GRAPHSOURCE%\rrds\SecEvents.rrd:SecSuccess:AVERAGE^
 AREA:SecInfo#0000FF88:Infos^
 LINE1:SecWarn#FCB514:Warning^
 LINE1:SecErr#FF0000:Errors^
 LINE1:SecAuditFail#551A8B:AuditFailures^
 LINE1:SecAuditSuccess#8B1C62:AuditSuccess^
 LINE1:SecSuccess#00FF00:Success

 %SOURCE%\tools\rrdtool.exe graph %SOURCE%\pngs\weeklies\Network.png --start -1w -E^
 DEF:BytesIn=%GRAPHSOURCE%\rrds\Network.rrd:BytesIn:AVERAGE^
 DEF:BytesOut=%GRAPHSOURCE%\rrds\Network.rrd:BytesOut:AVERAGE^
 DEF:BytesTotal=%GRAPHSOURCE%\rrds\Network.rrd:BytesTotal:AVERAGE^
 LINE1:BytesIn#0000FF88:BytesIn^
 LINE1:BytesOut#FCB514:BytesOut^
 LINE1:BytesTotal#00FF00:BytesTotal

%SOURCE%\tools\rrdtool.exe graph %SOURCE%\pngs\weeklies\CPU.png --start -1w -E^
 DEF:CpuPriv=%GRAPHSOURCE%\rrds\CPU.rrd:CpuPriv:AVERAGE^
 DEF:CpuUser=%GRAPHSOURCE%\rrds\CPU.rrd:CpuUser:AVERAGE^
 DEF:CpuTotal=%GRAPHSOURCE%\rrds\CPU.rrd:CpuTotal:AVERAGE^
 LINE1:CpuPriv#0000FF88:CpuPriv^
 LINE1:CpuUser#FCB514:CpuUser^
 LINE1:CpuTotal#FF0000:CpuTotal


%SOURCE%\tools\rrdtool.exe graph %SOURCE%\pngs\weeklies\DiskUsage.png --start -1w -E^
 DEF:DiskAvgQ=%GRAPHSOURCE%\rrds\DriveUsage.rrd:DiskAvgQ:AVERAGE^
 DEF:DiskAvgQRead=%GRAPHSOURCE%\rrds\DriveUsage.rrd:DiskAvgQRead:AVERAGE^
 DEF:DiskAvgQWrite=%GRAPHSOURCE%\rrds\DriveUsage.rrd:DiskAvgQWrite:AVERAGE^
 DEF:DiskAvgBytesRead=%GRAPHSOURCE%\rrds\DriveUsage.rrd:DiskAvgBytesRead:AVERAGE^
 DEF:DiskAvgBytesWrite=%GRAPHSOURCE%\rrds\DriveUsage.rrd:DiskAvgBytesWrite:AVERAGE^
 LINE1:DiskAvgQ#0000FF88:DiskAvgQ^
 LINE1:DiskAvgQRead#FCB514:DiskAvgQRead^
 LINE1:DiskAvgQWrite#551A8B:DiskAvgQWrite^
 LINE1:DiskAvgBytesRead#8B1C62:DiskAvgBytesWrite^
 LINE1:DiskAvgBytesWrite#FF0000:DiskAvgBytesWrite

%SOURCE%\tools\rrdtool.exe graph %SOURCE%\pngs\weeklies\DriveSpace.png --start -1w -E^
 DEF:DrvCSpace=%GRAPHSOURCE%\rrds\DriveSpace.rrd:DrvCSpace:AVERAGE^
 DEF:DrvDSpace=%GRAPHSOURCE%\rrds\DriveSpace.rrd:DrvDSpace:AVERAGE^
 DEF:DrvESpace=%GRAPHSOURCE%\rrds\DriveSpace.rrd:DrvESpace:AVERAGE^
 LINE1:DrvCSpace#0000FF88:DrvCSpace^
 LINE1:DrvDSpace#FCB514:DrvDSpace^
 LINE1:DrvESpace#FF0000:DrvESpace

%SOURCE%\tools\rrdtool.exe graph %SOURCE%\pngs\weeklies\Memory.png --start -1w -E^
 DEF:MemCommittedBytes=%GRAPHSOURCE%\rrds\Memory.rrd:MemCommittedBytes:AVERAGE^
 DEF:MemPagesPerSec=%GRAPHSOURCE%\rrds\Memory.rrd:MemPagesPerSec:AVERAGE^
 DEF:MemAvailMBytes=%GRAPHSOURCE%\rrds\Memory.rrd:MemAvailMBytes:AVERAGE^
 LINE1:MemCommittedBytes#0000FF88:MemCommittedBytes^
 LINE1:MemPagesPerSec#FCB514:MemPagesPerSec^
 LINE1:MemAvailMBytes#FF0000:MemAvailMBytes

 %SOURCE%\tools\rrdtool.exe graph %SOURCE%\pngs\weeklies\IIS.png --start -1w -E^
 DEF:Twos=%GRAPHSOURCE%\rrds\IIS.rrd:Twos:AVERAGE^
 DEF:Threes=%GRAPHSOURCE%\rrds\IIS.rrd:Threes:AVERAGE^
 DEF:Fours=%GRAPHSOURCE%\rrds\IIS.rrd:Fours:AVERAGE^
 DEF:Fives=%GRAPHSOURCE%\rrds\IIS.rrd:Fives:AVERAGE^
 LINE1:Twos#0000FF88:Twos^
 LINE1:Threes#FCB514:Threes^
 LINE1:Fours#8B1C62:Fours^
 LINE1:Fives#FF0000:Fives
 
  %SOURCE%\tools\rrdtool.exe graph %SOURCE%\pngs\monthlies\AppEvents.png --start -1m -E^
 DEF:AppInfo=%GRAPHSOURCE%\rrds\AppEvents.rrd:AppInfo:AVERAGE^
 DEF:AppWarn=%GRAPHSOURCE%\rrds\AppEvents.rrd:AppWarn:AVERAGE^
 DEF:AppErr=%GRAPHSOURCE%\rrds\AppEvents.rrd:AppErr:AVERAGE^
 DEF:AppAuditFail=%GRAPHSOURCE%\rrds\AppEvents.rrd:AppAuditFail:AVERAGE^
 DEF:AppAuditSuccess=%GRAPHSOURCE%\rrds\AppEvents.rrd:AppAuditSuccess:AVERAGE^
 DEF:AppSuccess=%GRAPHSOURCE%\rrds\AppEvents.rrd:AppSuccess:AVERAGE^
 AREA:AppInfo#0000FF88:Infos^
 LINE1:AppWarn#FCB514:Warning^
 LINE1:AppErr#FF0000:Errors^
 LINE1:AppAuditFail#551A8B:AuditFailures^
 LINE1:AppAuditSuccess#8B1C62:AuditSuccess^
 LINE1:AppSuccess#00FF00:Success

%SOURCE%\tools\rrdtool.exe graph %SOURCE%\pngs\monthlies\SysEvents.png --start -1m -E^
 DEF:SysInfo=%GRAPHSOURCE%\rrds\SysEvents.rrd:SysInfo:AVERAGE^
 DEF:SysWarn=%GRAPHSOURCE%\rrds\SysEvents.rrd:SysWarn:AVERAGE^
 DEF:SysErr=%GRAPHSOURCE%\rrds\SysEvents.rrd:SysErr:AVERAGE^
 DEF:SysAuditFail=%GRAPHSOURCE%\rrds\SysEvents.rrd:SysAuditFail:AVERAGE^
 DEF:SysAuditSuccess=%GRAPHSOURCE%\rrds\SysEvents.rrd:SysAuditSuccess:AVERAGE^
 DEF:SysSuccess=%GRAPHSOURCE%\rrds\SysEvents.rrd:SysSuccess:AVERAGE^
 AREA:SysInfo#0000FF88:Infos^
 LINE1:SysWarn#FCB514:Warning^
 LINE1:SysErr#FF0000:Errors^
 LINE1:SysAuditFail#551A8B:AuditFailures^
 LINE1:SysAuditSuccess#8B1C62:AuditSuccess^
 LINE1:SysSuccess#00FF00:Success

%SOURCE%\tools\rrdtool.exe graph %SOURCE%\pngs\monthlies\SecEvents.png --start -1m -E^
 DEF:SecInfo=%GRAPHSOURCE%\rrds\SecEvents.rrd:SecInfo:AVERAGE^
 DEF:SecWarn=%GRAPHSOURCE%\rrds\SecEvents.rrd:SecWarn:AVERAGE^
 DEF:SecErr=%GRAPHSOURCE%\rrds\SecEvents.rrd:SecErr:AVERAGE^
 DEF:SecAuditFail=%GRAPHSOURCE%\rrds\SecEvents.rrd:SecAuditFail:AVERAGE^
 DEF:SecAuditSuccess=%GRAPHSOURCE%\rrds\SecEvents.rrd:SecAuditSuccess:AVERAGE^
 DEF:SecSuccess=%GRAPHSOURCE%\rrds\SecEvents.rrd:SecSuccess:AVERAGE^
 AREA:SecInfo#0000FF88:Infos^
 LINE1:SecWarn#FCB514:Warning^
 LINE1:SecErr#FF0000:Errors^
 LINE1:SecAuditFail#551A8B:AuditFailures^
 LINE1:SecAuditSuccess#8B1C62:AuditSuccess^
 LINE1:SecSuccess#00FF00:Success

 %SOURCE%\tools\rrdtool.exe graph %SOURCE%\pngs\monthlies\Network.png --start -1m -E^
 DEF:BytesIn=%GRAPHSOURCE%\rrds\Network.rrd:BytesIn:AVERAGE^
 DEF:BytesOut=%GRAPHSOURCE%\rrds\Network.rrd:BytesOut:AVERAGE^
 DEF:BytesTotal=%GRAPHSOURCE%\rrds\Network.rrd:BytesTotal:AVERAGE^
 LINE1:BytesIn#0000FF88:BytesIn^
 LINE1:BytesOut#FCB514:BytesOut^
 LINE1:BytesTotal#00FF00:BytesTotal

%SOURCE%\tools\rrdtool.exe graph %SOURCE%\pngs\monthlies\CPU.png --start -1m -E^
 DEF:CpuPriv=%GRAPHSOURCE%\rrds\CPU.rrd:CpuPriv:AVERAGE^
 DEF:CpuUser=%GRAPHSOURCE%\rrds\CPU.rrd:CpuUser:AVERAGE^
 DEF:CpuTotal=%GRAPHSOURCE%\rrds\CPU.rrd:CpuTotal:AVERAGE^
 LINE1:CpuPriv#0000FF88:CpuPriv^
 LINE1:CpuUser#FCB514:CpuUser^
 LINE1:CpuTotal#FF0000:CpuTotal


%SOURCE%\tools\rrdtool.exe graph %SOURCE%\pngs\monthlies\DiskUsage.png --start -1m -E^
 DEF:DiskAvgQ=%GRAPHSOURCE%\rrds\DriveUsage.rrd:DiskAvgQ:AVERAGE^
 DEF:DiskAvgQRead=%GRAPHSOURCE%\rrds\DriveUsage.rrd:DiskAvgQRead:AVERAGE^
 DEF:DiskAvgQWrite=%GRAPHSOURCE%\rrds\DriveUsage.rrd:DiskAvgQWrite:AVERAGE^
 DEF:DiskAvgBytesRead=%GRAPHSOURCE%\rrds\DriveUsage.rrd:DiskAvgBytesRead:AVERAGE^
 DEF:DiskAvgBytesWrite=%GRAPHSOURCE%\rrds\DriveUsage.rrd:DiskAvgBytesWrite:AVERAGE^
 LINE1:DiskAvgQ#0000FF88:DiskAvgQ^
 LINE1:DiskAvgQRead#FCB514:DiskAvgQRead^
 LINE1:DiskAvgQWrite#551A8B:DiskAvgQWrite^
 LINE1:DiskAvgBytesRead#8B1C62:DiskAvgBytesWrite^
 LINE1:DiskAvgBytesWrite#FF0000:DiskAvgBytesWrite

%SOURCE%\tools\rrdtool.exe graph %SOURCE%\pngs\monthlies\DriveSpace.png --start -1m -E^
 DEF:DrvCSpace=%GRAPHSOURCE%\rrds\DriveSpace.rrd:DrvCSpace:AVERAGE^
 DEF:DrvDSpace=%GRAPHSOURCE%\rrds\DriveSpace.rrd:DrvDSpace:AVERAGE^
 DEF:DrvESpace=%GRAPHSOURCE%\rrds\DriveSpace.rrd:DrvESpace:AVERAGE^
 LINE1:DrvCSpace#0000FF88:DrvCSpace^
 LINE1:DrvDSpace#FCB514:DrvDSpace^
 LINE1:DrvESpace#FF0000:DrvESpace

%SOURCE%\tools\rrdtool.exe graph %SOURCE%\pngs\monthlies\Memory.png --start -1m -E^
 DEF:MemCommittedBytes=%GRAPHSOURCE%\rrds\Memory.rrd:MemCommittedBytes:AVERAGE^
 DEF:MemPagesPerSec=%GRAPHSOURCE%\rrds\Memory.rrd:MemPagesPerSec:AVERAGE^
 DEF:MemAvailMBytes=%GRAPHSOURCE%\rrds\Memory.rrd:MemAvailMBytes:AVERAGE^
 LINE1:MemCommittedBytes#0000FF88:MemCommittedBytes^
 LINE1:MemPagesPerSec#FCB514:MemPagesPerSec^
 LINE1:MemAvailMBytes#FF0000:MemAvailMBytes

 %SOURCE%\tools\rrdtool.exe graph %SOURCE%\pngs\monthlies\IIS.png --start -1m -E^
 DEF:Twos=%GRAPHSOURCE%\rrds\IIS.rrd:Twos:AVERAGE^
 DEF:Threes=%GRAPHSOURCE%\rrds\IIS.rrd:Threes:AVERAGE^
 DEF:Fours=%GRAPHSOURCE%\rrds\IIS.rrd:Fours:AVERAGE^
 DEF:Fives=%GRAPHSOURCE%\rrds\IIS.rrd:Fives:AVERAGE^
 LINE1:Twos#0000FF88:Twos^
 LINE1:Threes#FCB514:Threes^
 LINE1:Fours#8B1C62:Fours^
 LINE1:Fives#FF0000:Fives
 
  %SOURCE%\tools\rrdtool.exe graph %SOURCE%\pngs\quarterlies\AppEvents.png --start -3m -E^
 DEF:AppInfo=%GRAPHSOURCE%\rrds\AppEvents.rrd:AppInfo:AVERAGE^
 DEF:AppWarn=%GRAPHSOURCE%\rrds\AppEvents.rrd:AppWarn:AVERAGE^
 DEF:AppErr=%GRAPHSOURCE%\rrds\AppEvents.rrd:AppErr:AVERAGE^
 DEF:AppAuditFail=%GRAPHSOURCE%\rrds\AppEvents.rrd:AppAuditFail:AVERAGE^
 DEF:AppAuditSuccess=%GRAPHSOURCE%\rrds\AppEvents.rrd:AppAuditSuccess:AVERAGE^
 DEF:AppSuccess=%GRAPHSOURCE%\rrds\AppEvents.rrd:AppSuccess:AVERAGE^
 AREA:AppInfo#0000FF88:Infos^
 LINE1:AppWarn#FCB514:Warning^
 LINE1:AppErr#FF0000:Errors^
 LINE1:AppAuditFail#551A8B:AuditFailures^
 LINE1:AppAuditSuccess#8B1C62:AuditSuccess^
 LINE1:AppSuccess#00FF00:Success

%SOURCE%\tools\rrdtool.exe graph %SOURCE%\pngs\quarterlies\SysEvents.png --start -3m -E^
 DEF:SysInfo=%GRAPHSOURCE%\rrds\SysEvents.rrd:SysInfo:AVERAGE^
 DEF:SysWarn=%GRAPHSOURCE%\rrds\SysEvents.rrd:SysWarn:AVERAGE^
 DEF:SysErr=%GRAPHSOURCE%\rrds\SysEvents.rrd:SysErr:AVERAGE^
 DEF:SysAuditFail=%GRAPHSOURCE%\rrds\SysEvents.rrd:SysAuditFail:AVERAGE^
 DEF:SysAuditSuccess=%GRAPHSOURCE%\rrds\SysEvents.rrd:SysAuditSuccess:AVERAGE^
 DEF:SysSuccess=%GRAPHSOURCE%\rrds\SysEvents.rrd:SysSuccess:AVERAGE^
 AREA:SysInfo#0000FF88:Infos^
 LINE1:SysWarn#FCB514:Warning^
 LINE1:SysErr#FF0000:Errors^
 LINE1:SysAuditFail#551A8B:AuditFailures^
 LINE1:SysAuditSuccess#8B1C62:AuditSuccess^
 LINE1:SysSuccess#00FF00:Success

%SOURCE%\tools\rrdtool.exe graph %SOURCE%\pngs\quarterlies\SecEvents.png --start -3m -E^
 DEF:SecInfo=%GRAPHSOURCE%\rrds\SecEvents.rrd:SecInfo:AVERAGE^
 DEF:SecWarn=%GRAPHSOURCE%\rrds\SecEvents.rrd:SecWarn:AVERAGE^
 DEF:SecErr=%GRAPHSOURCE%\rrds\SecEvents.rrd:SecErr:AVERAGE^
 DEF:SecAuditFail=%GRAPHSOURCE%\rrds\SecEvents.rrd:SecAuditFail:AVERAGE^
 DEF:SecAuditSuccess=%GRAPHSOURCE%\rrds\SecEvents.rrd:SecAuditSuccess:AVERAGE^
 DEF:SecSuccess=%GRAPHSOURCE%\rrds\SecEvents.rrd:SecSuccess:AVERAGE^
 AREA:SecInfo#0000FF88:Infos^
 LINE1:SecWarn#FCB514:Warning^
 LINE1:SecErr#FF0000:Errors^
 LINE1:SecAuditFail#551A8B:AuditFailures^
 LINE1:SecAuditSuccess#8B1C62:AuditSuccess^
 LINE1:SecSuccess#00FF00:Success

 %SOURCE%\tools\rrdtool.exe graph %SOURCE%\pngs\quarterlies\Network.png --start -3m -E^
 DEF:BytesIn=%GRAPHSOURCE%\rrds\Network.rrd:BytesIn:AVERAGE^
 DEF:BytesOut=%GRAPHSOURCE%\rrds\Network.rrd:BytesOut:AVERAGE^
 DEF:BytesTotal=%GRAPHSOURCE%\rrds\Network.rrd:BytesTotal:AVERAGE^
 LINE1:BytesIn#0000FF88:BytesIn^
 LINE1:BytesOut#FCB514:BytesOut^
 LINE1:BytesTotal#00FF00:BytesTotal

%SOURCE%\tools\rrdtool.exe graph %SOURCE%\pngs\quarterlies\CPU.png --start -3m -E^
 DEF:CpuPriv=%GRAPHSOURCE%\rrds\CPU.rrd:CpuPriv:AVERAGE^
 DEF:CpuUser=%GRAPHSOURCE%\rrds\CPU.rrd:CpuUser:AVERAGE^
 DEF:CpuTotal=%GRAPHSOURCE%\rrds\CPU.rrd:CpuTotal:AVERAGE^
 LINE1:CpuPriv#0000FF88:CpuPriv^
 LINE1:CpuUser#FCB514:CpuUser^
 LINE1:CpuTotal#FF0000:CpuTotal


%SOURCE%\tools\rrdtool.exe graph %SOURCE%\pngs\quarterlies\DiskUsage.png --start -3m -E^
 DEF:DiskAvgQ=%GRAPHSOURCE%\rrds\DriveUsage.rrd:DiskAvgQ:AVERAGE^
 DEF:DiskAvgQRead=%GRAPHSOURCE%\rrds\DriveUsage.rrd:DiskAvgQRead:AVERAGE^
 DEF:DiskAvgQWrite=%GRAPHSOURCE%\rrds\DriveUsage.rrd:DiskAvgQWrite:AVERAGE^
 DEF:DiskAvgBytesRead=%GRAPHSOURCE%\rrds\DriveUsage.rrd:DiskAvgBytesRead:AVERAGE^
 DEF:DiskAvgBytesWrite=%GRAPHSOURCE%\rrds\DriveUsage.rrd:DiskAvgBytesWrite:AVERAGE^
 LINE1:DiskAvgQ#0000FF88:DiskAvgQ^
 LINE1:DiskAvgQRead#FCB514:DiskAvgQRead^
 LINE1:DiskAvgQWrite#551A8B:DiskAvgQWrite^
 LINE1:DiskAvgBytesRead#8B1C62:DiskAvgBytesWrite^
 LINE1:DiskAvgBytesWrite#FF0000:DiskAvgBytesWrite

%SOURCE%\tools\rrdtool.exe graph %SOURCE%\pngs\quarterlies\DriveSpace.png --start -3m -E^
 DEF:DrvCSpace=%GRAPHSOURCE%\rrds\DriveSpace.rrd:DrvCSpace:AVERAGE^
 DEF:DrvDSpace=%GRAPHSOURCE%\rrds\DriveSpace.rrd:DrvDSpace:AVERAGE^
 DEF:DrvESpace=%GRAPHSOURCE%\rrds\DriveSpace.rrd:DrvESpace:AVERAGE^
 LINE1:DrvCSpace#0000FF88:DrvCSpace^
 LINE1:DrvDSpace#FCB514:DrvDSpace^
 LINE1:DrvESpace#FF0000:DrvESpace

%SOURCE%\tools\rrdtool.exe graph %SOURCE%\pngs\quarterlies\Memory.png --start -3m -E^
 DEF:MemCommittedBytes=%GRAPHSOURCE%\rrds\Memory.rrd:MemCommittedBytes:AVERAGE^
 DEF:MemPagesPerSec=%GRAPHSOURCE%\rrds\Memory.rrd:MemPagesPerSec:AVERAGE^
 DEF:MemAvailMBytes=%GRAPHSOURCE%\rrds\Memory.rrd:MemAvailMBytes:AVERAGE^
 LINE1:MemCommittedBytes#0000FF88:MemCommittedBytes^
 LINE1:MemPagesPerSec#FCB514:MemPagesPerSec^
 LINE1:MemAvailMBytes#FF0000:MemAvailMBytes

 %SOURCE%\tools\rrdtool.exe graph %SOURCE%\pngs\quarterlies\IIS.png --start -3m -E^
 DEF:Twos=%GRAPHSOURCE%\rrds\IIS.rrd:Twos:AVERAGE^
 DEF:Threes=%GRAPHSOURCE%\rrds\IIS.rrd:Threes:AVERAGE^
 DEF:Fours=%GRAPHSOURCE%\rrds\IIS.rrd:Fours:AVERAGE^
 DEF:Fives=%GRAPHSOURCE%\rrds\IIS.rrd:Fives:AVERAGE^
 LINE1:Twos#0000FF88:Twos^
 LINE1:Threes#FCB514:Threes^
 LINE1:Fours#8B1C62:Fours^
 LINE1:Fives#FF0000:Fives
 
  %SOURCE%\tools\rrdtool.exe graph %SOURCE%\pngs\yearlies\AppEvents.png --start -1y -E^
 DEF:AppInfo=%GRAPHSOURCE%\rrds\AppEvents.rrd:AppInfo:AVERAGE^
 DEF:AppWarn=%GRAPHSOURCE%\rrds\AppEvents.rrd:AppWarn:AVERAGE^
 DEF:AppErr=%GRAPHSOURCE%\rrds\AppEvents.rrd:AppErr:AVERAGE^
 DEF:AppAuditFail=%GRAPHSOURCE%\rrds\AppEvents.rrd:AppAuditFail:AVERAGE^
 DEF:AppAuditSuccess=%GRAPHSOURCE%\rrds\AppEvents.rrd:AppAuditSuccess:AVERAGE^
 DEF:AppSuccess=%GRAPHSOURCE%\rrds\AppEvents.rrd:AppSuccess:AVERAGE^
 AREA:AppInfo#0000FF88:Infos^
 LINE1:AppWarn#FCB514:Warning^
 LINE1:AppErr#FF0000:Errors^
 LINE1:AppAuditFail#551A8B:AuditFailures^
 LINE1:AppAuditSuccess#8B1C62:AuditSuccess^
 LINE1:AppSuccess#00FF00:Success

%SOURCE%\tools\rrdtool.exe graph %SOURCE%\pngs\yearlies\SysEvents.png --start -1y -E^
 DEF:SysInfo=%GRAPHSOURCE%\rrds\SysEvents.rrd:SysInfo:AVERAGE^
 DEF:SysWarn=%GRAPHSOURCE%\rrds\SysEvents.rrd:SysWarn:AVERAGE^
 DEF:SysErr=%GRAPHSOURCE%\rrds\SysEvents.rrd:SysErr:AVERAGE^
 DEF:SysAuditFail=%GRAPHSOURCE%\rrds\SysEvents.rrd:SysAuditFail:AVERAGE^
 DEF:SysAuditSuccess=%GRAPHSOURCE%\rrds\SysEvents.rrd:SysAuditSuccess:AVERAGE^
 DEF:SysSuccess=%GRAPHSOURCE%\rrds\SysEvents.rrd:SysSuccess:AVERAGE^
 AREA:SysInfo#0000FF88:Infos^
 LINE1:SysWarn#FCB514:Warning^
 LINE1:SysErr#FF0000:Errors^
 LINE1:SysAuditFail#551A8B:AuditFailures^
 LINE1:SysAuditSuccess#8B1C62:AuditSuccess^
 LINE1:SysSuccess#00FF00:Success

%SOURCE%\tools\rrdtool.exe graph %SOURCE%\pngs\yearlies\SecEvents.png --start -1y -E^
 DEF:SecInfo=%GRAPHSOURCE%\rrds\SecEvents.rrd:SecInfo:AVERAGE^
 DEF:SecWarn=%GRAPHSOURCE%\rrds\SecEvents.rrd:SecWarn:AVERAGE^
 DEF:SecErr=%GRAPHSOURCE%\rrds\SecEvents.rrd:SecErr:AVERAGE^
 DEF:SecAuditFail=%GRAPHSOURCE%\rrds\SecEvents.rrd:SecAuditFail:AVERAGE^
 DEF:SecAuditSuccess=%GRAPHSOURCE%\rrds\SecEvents.rrd:SecAuditSuccess:AVERAGE^
 DEF:SecSuccess=%GRAPHSOURCE%\rrds\SecEvents.rrd:SecSuccess:AVERAGE^
 AREA:SecInfo#0000FF88:Infos^
 LINE1:SecWarn#FCB514:Warning^
 LINE1:SecErr#FF0000:Errors^
 LINE1:SecAuditFail#551A8B:AuditFailures^
 LINE1:SecAuditSuccess#8B1C62:AuditSuccess^
 LINE1:SecSuccess#00FF00:Success

 %SOURCE%\tools\rrdtool.exe graph %SOURCE%\pngs\yearlies\Network.png --start -1y -E^
 DEF:BytesIn=%GRAPHSOURCE%\rrds\Network.rrd:BytesIn:AVERAGE^
 DEF:BytesOut=%GRAPHSOURCE%\rrds\Network.rrd:BytesOut:AVERAGE^
 DEF:BytesTotal=%GRAPHSOURCE%\rrds\Network.rrd:BytesTotal:AVERAGE^
 LINE1:BytesIn#0000FF88:BytesIn^
 LINE1:BytesOut#FCB514:BytesOut^
 LINE1:BytesTotal#00FF00:BytesTotal

%SOURCE%\tools\rrdtool.exe graph %SOURCE%\pngs\yearlies\CPU.png --start -1y -E^
 DEF:CpuPriv=%GRAPHSOURCE%\rrds\CPU.rrd:CpuPriv:AVERAGE^
 DEF:CpuUser=%GRAPHSOURCE%\rrds\CPU.rrd:CpuUser:AVERAGE^
 DEF:CpuTotal=%GRAPHSOURCE%\rrds\CPU.rrd:CpuTotal:AVERAGE^
 LINE1:CpuPriv#0000FF88:CpuPriv^
 LINE1:CpuUser#FCB514:CpuUser^
 LINE1:CpuTotal#FF0000:CpuTotal


%SOURCE%\tools\rrdtool.exe graph %SOURCE%\pngs\yearlies\DiskUsage.png --start -1y -E^
 DEF:DiskAvgQ=%GRAPHSOURCE%\rrds\DriveUsage.rrd:DiskAvgQ:AVERAGE^
 DEF:DiskAvgQRead=%GRAPHSOURCE%\rrds\DriveUsage.rrd:DiskAvgQRead:AVERAGE^
 DEF:DiskAvgQWrite=%GRAPHSOURCE%\rrds\DriveUsage.rrd:DiskAvgQWrite:AVERAGE^
 DEF:DiskAvgBytesRead=%GRAPHSOURCE%\rrds\DriveUsage.rrd:DiskAvgBytesRead:AVERAGE^
 DEF:DiskAvgBytesWrite=%GRAPHSOURCE%\rrds\DriveUsage.rrd:DiskAvgBytesWrite:AVERAGE^
 LINE1:DiskAvgQ#0000FF88:DiskAvgQ^
 LINE1:DiskAvgQRead#FCB514:DiskAvgQRead^
 LINE1:DiskAvgQWrite#551A8B:DiskAvgQWrite^
 LINE1:DiskAvgBytesRead#8B1C62:DiskAvgBytesWrite^
 LINE1:DiskAvgBytesWrite#FF0000:DiskAvgBytesWrite

%SOURCE%\tools\rrdtool.exe graph %SOURCE%\pngs\yearlies\DriveSpace.png --start -1y -E^
 DEF:DrvCSpace=%GRAPHSOURCE%\rrds\DriveSpace.rrd:DrvCSpace:AVERAGE^
 DEF:DrvDSpace=%GRAPHSOURCE%\rrds\DriveSpace.rrd:DrvDSpace:AVERAGE^
 DEF:DrvESpace=%GRAPHSOURCE%\rrds\DriveSpace.rrd:DrvESpace:AVERAGE^
 LINE1:DrvCSpace#0000FF88:DrvCSpace^
 LINE1:DrvDSpace#FCB514:DrvDSpace^
 LINE1:DrvESpace#FF0000:DrvESpace

%SOURCE%\tools\rrdtool.exe graph %SOURCE%\pngs\yearlies\Memory.png --start -1y -E^
 DEF:MemCommittedBytes=%GRAPHSOURCE%\rrds\Memory.rrd:MemCommittedBytes:AVERAGE^
 DEF:MemPagesPerSec=%GRAPHSOURCE%\rrds\Memory.rrd:MemPagesPerSec:AVERAGE^
 DEF:MemAvailMBytes=%GRAPHSOURCE%\rrds\Memory.rrd:MemAvailMBytes:AVERAGE^
 LINE1:MemCommittedBytes#0000FF88:MemCommittedBytes^
 LINE1:MemPagesPerSec#FCB514:MemPagesPerSec^
 LINE1:MemAvailMBytes#FF0000:MemAvailMBytes

 %SOURCE%\tools\rrdtool.exe graph %SOURCE%\pngs\yearlies\IIS.png --start -1y -E^
 DEF:Twos=%GRAPHSOURCE%\rrds\IIS.rrd:Twos:AVERAGE^
 DEF:Threes=%GRAPHSOURCE%\rrds\IIS.rrd:Threes:AVERAGE^
 DEF:Fours=%GRAPHSOURCE%\rrds\IIS.rrd:Fours:AVERAGE^
 DEF:Fives=%GRAPHSOURCE%\rrds\IIS.rrd:Fives:AVERAGE^
 LINE1:Twos#0000FF88:Twos^
 LINE1:Threes#FCB514:Threes^
 LINE1:Fours#8B1C62:Fours^
 LINE1:Fives#FF0000:Fives
 
:END
