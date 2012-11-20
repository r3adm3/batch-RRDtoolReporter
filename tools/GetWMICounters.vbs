
' *****************************************************************************
'  Setup WMI constants
' *****************************************************************************
Const wbemFlagReturnImmediately = &h10
Const wbemFlagForwardOnly = &h20

arrComputers = Array(".")
For Each strComputer In arrComputers
' *****************************************************************************
'  Run through the Computers Array...for each in the array do this...
' *****************************************************************************

' *****************************************************************************
'   Start the WMI object 
' *****************************************************************************
   Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\CIMV2")

' *****************************************************************************
'  Collect Network stats 
' *****************************************************************************
   Set colItems = objWMIService.ExecQuery("SELECT * FROM Win32_PerfFormattedData_Tcpip_NetworkInterface", "WQL", _
                                          wbemFlagReturnImmediately + wbemFlagForwardOnly)  

   For Each objItem In colItems

      strBytesIn = strBytesIn + objItem.BytesReceivedPersec
      strBytesOut = strBytesOut + objItem.BytesSentPersec
      strBytesTotal = strBytesTotal + objItem.BytesTotalPersec
 
   Next
 
' *****************************************************************************
'  Collect CPU Stats 
' *****************************************************************************
    Set colItems2 = objWMIService.ExecQuery("SELECT * FROM Win32_PerfFormattedData_PerfOS_Processor", "WQL", _
                                          wbemFlagReturnImmediately + wbemFlagForwardOnly)
   For Each objItem2 In colItems2

   if objItem2.Name = "_Total" then

	strPcTotalTime = objItem2.PercentProcessorTime
	strPcUserTime = objItem2.PercentUserTime
	strPcPrivTime = objItem2.PercentPrivilegedTime
	
	end if


   Next
 
' *****************************************************************************
'  Collect Disk Space stats 
' *****************************************************************************
  Set colItems3 = objWMIService.ExecQuery("SELECT * FROM Win32_LogicalDisk", "WQL", _
                                          wbemFlagReturnImmediately + wbemFlagForwardOnly)

   For Each objItem3 In colItems3

	select case objItem3.Caption

		case "C:"
			strCdrive = Int ((objItem3.FreeSpace/objItem3.Size ) * 100)
		case "D:"
			strDdrive = Int ((objItem3.FreeSpace/objItem3.Size ) * 100)
		case "E:"
			strEdrive = Int ((objItem3.FreeSpace/objItem3.Size ) * 100)
		case "F:" 
			strFdrive = Int ((objItem3.FreeSpace/objItem3.Size ) * 100)
		case "G:"
			strGdrive = Int ((objItem3.FreeSpace/objItem3.Size ) * 100)
			
	end select 

	Next
	
Next

' *****************************************************************************
'  Memory stats
' *****************************************************************************
Set colItems4 = objWMIService.ExecQuery( _
    "SELECT * FROM Win32_PerfFormattedData_PerfOS_Memory",,48) 
For Each objItem4 in colItems4 
    strPcCommitedBytes = objItem4.PercentCommittedBytesInUse
	strPagesPerSec = objItem4.PagesPerSec
	strAvailableMBytes = objItem4.AvailableMBytes
Next

' *****************************************************************************
'  Physical Disk stats 
' *****************************************************************************
Set colItems5 = objWMIService.ExecQuery( _
    "SELECT * FROM Win32_PerfFormattedData_PerfDisk_PhysicalDisk",,48) 
For Each objItem5 in colItems5
    strAvgDiskQueueLength = objItem5.AvgDiskQueueLength
    strAvgDiskReadQueueLength = objItem5.AvgDiskReadQueueLength
    strAvgDiskWriteQueueLength = objItem5.AvgDiskWriteQueueLength
    strDiskReadBytesPersec = objItem5.DiskReadBytesPersec
    strDiskWriteBytesPersec = objItem5.DiskWriteBytesPersec
Next

' *****************************************************************************
'  Display Data 
' *****************************************************************************
wscript.echo "Network:" & strBytesIn & ":" & strBytesOut & ":" & strBytesTotal
wscript.echo "CPU:" & strPcTotalTime & ":" & strPcUserTime & ":" & strPcPrivTime
wscript.echo "DiskSpace:" & strCDrive & ":" & strDdrive & ":" & strEdrive & ":" & strFdrive & ":" & strGdrive
wscript.echo "DiskUsage:" & strAvgDiskQueueLength & ":" & strAvgDiskReadQueueLength & ":" & strAvgDiskWriteQueueLength & ":" & strDiskReadBytesPerSec & ":" & strDiskWriteBytesPerSec
wscript.echo "MemoryUsage:" & strPcCommitedBytes & ":" & strPagesPerSec & ":" & strAvailableMBytes
