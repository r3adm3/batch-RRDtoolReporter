REM ***************************************************************************
REM Create event log RRDs.
REM ***************************************************************************
..\rrdtool create SysEvents.rrd^
 DS:SysInfo:GAUGE:600:U:U^
 DS:SysWarn:GAUGE:600:U:U^
 DS:SysErr:GAUGE:600:U:U^
 DS:SysAuditFail:GAUGE:600:U:U^
 DS:SysAuditSuccess:GAUGE:600:U:U^
 DS:SysSuccess:GAUGE:600:U:U^
 RRA:AVERAGE:0.5:1:600^
 RRA:AVERAGE:0.5:6:700^
 RRA:AVERAGE:0.5:24:775^
 RRA:AVERAGE:0.5:288:797^
 RRA:MAX:0.5:1:600^
 RRA:MAX:0.5:6:700^
 RRA:MAX:0.5:24:775^
 RRA:MAX:0.5:288:797

..\rrdtool create SecEvents.rrd^
 DS:SecInfo:GAUGE:600:U:U^
 DS:SecWarn:GAUGE:600:U:U^
 DS:SecErr:GAUGE:600:U:U^
 DS:SecAuditFail:GAUGE:600:U:U^
 DS:SecAuditSuccess:GAUGE:600:U:U^
 DS:SecSuccess:GAUGE:600:U:U^
 RRA:AVERAGE:0.5:1:600^
 RRA:AVERAGE:0.5:6:700^
 RRA:AVERAGE:0.5:24:775^
 RRA:AVERAGE:0.5:288:797^
 RRA:MAX:0.5:1:600^
 RRA:MAX:0.5:6:700^
 RRA:MAX:0.5:24:775^
 RRA:MAX:0.5:288:797
 
..\rrdtool create AppEvents.rrd^
 DS:AppInfo:GAUGE:600:U:U^
 DS:AppWarn:GAUGE:600:U:U^
 DS:AppErr:GAUGE:600:U:U^
 DS:AppAuditFail:GAUGE:600:U:U^
 DS:AppAuditSuccess:GAUGE:600:U:U^
 DS:AppSuccess:GAUGE:600:U:U^
 RRA:AVERAGE:0.5:1:600^
 RRA:AVERAGE:0.5:6:700^
 RRA:AVERAGE:0.5:24:775^
 RRA:AVERAGE:0.5:288:797^
 RRA:MAX:0.5:1:600^
 RRA:MAX:0.5:6:700^
 RRA:MAX:0.5:24:775^
 RRA:MAX:0.5:288:797
 
REM ***************************************************************************
REM Create Network log RRDs.
REM ***************************************************************************
..\rrdtool create Network.rrd^
 DS:BytesIn:GAUGE:600:U:U^
 DS:BytesOut:GAUGE:600:U:U^
 DS:BytesTotal:GAUGE:600:U:U^
 RRA:AVERAGE:0.5:1:600^
 RRA:AVERAGE:0.5:6:700^
 RRA:AVERAGE:0.5:24:775^
 RRA:AVERAGE:0.5:288:797^
 RRA:MAX:0.5:1:600^
 RRA:MAX:0.5:6:700^
 RRA:MAX:0.5:24:775^
 RRA:MAX:0.5:288:797
 
REM ***************************************************************************
REM Create CPU log RRDs.
REM ***************************************************************************
 ..\rrdtool create CPU.rrd^
 DS:CpuPriv:GAUGE:600:U:U^
 DS:CpuUser:GAUGE:600:U:U^
 DS:CpuTotal:GAUGE:600:U:U^
 RRA:AVERAGE:0.5:1:600^
 RRA:AVERAGE:0.5:6:700^
 RRA:AVERAGE:0.5:24:775^
 RRA:AVERAGE:0.5:288:797^
 RRA:MAX:0.5:1:600^
 RRA:MAX:0.5:6:700^
 RRA:MAX:0.5:24:775^
 RRA:MAX:0.5:288:797
 
REM ***************************************************************************
REM Create Drive Space log RRDs.
REM ***************************************************************************
..\rrdtool create DriveSpace.rrd^
 DS:DrvCSpace:GAUGE:600:U:U^
 DS:DrvDSpace:GAUGE:600:U:U^
 DS:DrvESpace:GAUGE:600:U:U^
 RRA:AVERAGE:0.5:1:600^
 RRA:AVERAGE:0.5:6:700^
 RRA:AVERAGE:0.5:24:775^
 RRA:AVERAGE:0.5:288:797^
 RRA:MAX:0.5:1:600^
 RRA:MAX:0.5:6:700^
 RRA:MAX:0.5:24:775^
 RRA:MAX:0.5:288:797
 
REM ***************************************************************************
REM Create DriveUsage log RRDs.
REM ***************************************************************************
..\rrdtool create DriveUsage.rrd^
 DS:DiskAvgQ:GAUGE:600:U:U^
 DS:DiskAvgQRead:GAUGE:600:U:U^
 DS:DiskAvgQWrite:GAUGE:600:U:U^
 DS:DiskAvgBytesRead:GAUGE:600:U:U^
 DS:DiskAvgBytesWrite:GAUGE:600:U:U^
 RRA:AVERAGE:0.5:1:600^
 RRA:AVERAGE:0.5:6:700^
 RRA:AVERAGE:0.5:24:775^
 RRA:AVERAGE:0.5:288:797^
 RRA:MAX:0.5:1:600^
 RRA:MAX:0.5:6:700^
 RRA:MAX:0.5:24:775^
 RRA:MAX:0.5:288:797

REM ***************************************************************************
REM Create Memory log RRDs.
REM *************************************************************************** 
..\rrdtool create Memory.rrd^
 DS:MemCommittedBytes:GAUGE:600:U:U^
 DS:MemPagesPerSec:GAUGE:600:U:U^
 DS:MemAvailMBytes:GAUGE:600:U:U^
 RRA:AVERAGE:0.5:1:600^
 RRA:AVERAGE:0.5:6:700^
 RRA:AVERAGE:0.5:24:775^
 RRA:AVERAGE:0.5:288:797^
 RRA:MAX:0.5:1:600^
 RRA:MAX:0.5:6:700^
 RRA:MAX:0.5:24:775^
 RRA:MAX:0.5:288:797
 