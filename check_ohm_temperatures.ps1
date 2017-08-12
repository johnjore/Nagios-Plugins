<#
.SYNOPSIS
This is a PowerShell script used by NSClient++ to check the temperatures on a host running Windows.
NSClient++ can then be called by Nagios (Op5 Monitor, Icinga or similar) to run this script.

.DESCRIPTION
Open Hardware Monitor (openhardwaremonitor.org) is used as a driver for the temperature sensors.
Open Hardware monitor creates WMI objects of all the found sensors.
This script retrieves the temperatures from those WMI objects.
This means that you have to download and run OpenHardwareMonitor.exe before running this check.

All the found temperatures will be output as performance data so that they can be graphed.

Define the command in nsclient++:
cmd /c echo scripts\custom\check_temperatures.ps1 -warning $ARG1$ -critical $ARG2$; exit($lastexitcode) | powershell.exe -command -
or you can omit or hard code the warning and critical arguments in case you do not permit sending arguments to nsclient.

.EXAMPLE
.\check_ohm_temperatures.ps1 -warning 80 -critical 90

.NOTES
Licensed under the Apache license version 2.
Written by farid.joubbi@consign.se

1.2 2017-08-12 Modified by John Jore. Accepts additional parameters for customizations. Working examples:
    check_cpufan=cmd /c echo scripts\\check_ohm_temperatures.ps1 -Name "CPU Fan" -warning 1200 -critical 1000 -Query "SELECT * FROM Sensor WHERE Name='CPU Fan'"; exit $LastExitCode | powershell.exe -ExecutionPolicy byPass -noprofile -command -
    check_systmp=cmd /c echo scripts\\check_ohm_temperatures.ps1 -Name "System Temp" -warning 70 -critical 80 -Query "SELECT * FROM Sensor WHERE Name='System'"; exit $LastExitCode | powershell.exe -ExecutionPolicy byPass -noprofile -command -
    check_cpucore1=cmd /c echo scripts\\check_ohm_temperatures.ps1 -Name "CPU Core 1 Temp" -warning 95 -critical 99 -Query "SELECT * FROM Sensor WHERE Name='CPU Core #1'"; exit $LastExitCode | powershell.exe -ExecutionPolicy byPass -noprofile -command -
    check_cpucore2=cmd /c echo scripts\\check_ohm_temperatures.ps1 -Name "CPU Core 2 Temp" -warning 95 -critical 99 -Query "SELECT * FROM Sensor WHERE Name='CPU Core #2'"; exit $LastExitCode | powershell.exe -ExecutionPolicy byPass -noprofile -command -
    check_cputmp=cmd /c echo scripts\\check_ohm_temperatures.ps1 -Name "CPU Temp" -warning 95 -critical 99 -Query "SELECT * FROM Sensor WHERE Name='CPU'"; exit $LastExitCode | powershell.exe -ExecutionPolicy byPass -noprofile -command -
    check_hdtmp=cmd /c echo scripts\\check_ohm_temperatures.ps1 -Name "HD Temp" -warning 58 -critical 60 -Query "SELECT * FROM Sensor WHERE Name='Temperature'"; exit $LastExitCode | powershell.exe -ExecutionPolicy byPass -noprofile -command -    
1.1 2016-03-24 Minor cleanup of variables and documentation.
1.0 2016-03-11 Initial release.

.LINK
http://consign.se/monitoring/
http://nsclient.org/
http://openhardwaremonitor.org/

#>

param (
    [Int]
    [string]$warning = 70,
    [Int]
    [string]$critical = 80,
    [string]$Query = "SELECT * FROM Sensor WHERE Sensortype='Temperature'",
    [string]$Name = "Name"
)

$status='OK'

# Check if Open Hardware Monitor is running.
if ((Get-Process -Name OpenHardwareMonitor -ErrorAction SilentlyContinue) -eq $null) {
    write-host 'OpenHardwareMonitor.exe not running!'
    exit 3
}

# Check that critical is set to higher than warning
#if ($warning -gt $critical) {
#    write-host 'warning set to higher than critical temperature!'
#    exit 3
#}

# Get the temperatures from all the found sensors and check them
$temperatures = Get-WmiObject -Namespace "Root\OpenHardwareMonitor" -Query $Query | sort-object Identifier
  # -Query "SELECT * FROM Sensor WHERE Sensortype='Temperature'" | sort-object Identifier
  # -Query "SELECT * FROM Sensor WHERE Name='CPU Core #1'" | sort-object Identifier
  # -Query "SELECT * FROM Sensor WHERE Name='Temperature'"  | sort-object Identifier

$temperature_string = foreach ($result in $temperatures){
    #$result.Identifier = $result.Identifier -replace '^/','' -replace 'temperature/',''
    $Result = [math]::Round($result.Value)
    '{0}' -f $Result

    if ($warning -gt $critical) {
        if ($result -lt $warning) { $status = 'WARNING'}
        if ($result -lt $critical) { $status = 'CRITICAL'}
    }
    else
    {
        if ($result -gt $warning) { $status = 'WARNING'}
        if ($result -gt $critical) { $status = 'CRITICAL'}
    }
}

write-host "$Name - $status - $temperature_string"
if ($status -eq 'WARNING') { exit 1 }
if ($status -eq 'CRITICAL') { exit 2 }
exit 0
