REM ***************************************************************************
REM Create IIS log RRDs.
REM ***************************************************************************
..\tools\rrdtool create IIS.rrd^
 DS:Twos:GAUGE:600:U:U^
 DS:Threes:GAUGE:600:U:U^
 DS:Fours:GAUGE:600:U:U^
 DS:Fives:GAUGE:600:U:U^
 RRA:AVERAGE:0.5:1:600^
 RRA:AVERAGE:0.5:6:700^
 RRA:AVERAGE:0.5:24:775^
 RRA:AVERAGE:0.5:288:797^
 RRA:MAX:0.5:1:600^
 RRA:MAX:0.5:6:700^
 RRA:MAX:0.5:24:775^
 RRA:MAX:0.5:288:797