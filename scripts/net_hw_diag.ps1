# ====================================================
# COMPUTER PULSE - HARDWARE & NETWORK DIAGNOSTIC AGENT
# ====================================================

$LogFile = "data\network_hardware.log"

Write-Host "[PROCESSING] Running Hardware and Network Diagnostics..." -ForegroundColor Cyan

# 1. SOFTWARE & PROCESS STATISTICS
$processCount = (Get-Process).Count
$topProcesses = Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 3 Name, @{Name="RAM_MB"; Expression={[math]::Round($_.WorkingSet64 / 1MB, 2)}}

# 2. HARDWARE & DISK METRICS
$cpuLoad = (Get-CimInstance Win32_Processor).LoadPercentage
$disks   = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | Select-Object DeviceID, @{Name="FreeGB"; Expression={[math]::Round($_.FreeSpace / 1GB, 2)}}, @{Name="TotalGB"; Expression={[math]::Round($_.Size / 1GB, 2)}}

# 3. NETWORK DIAGNOSTICS & LATENCY
$netAdapter = Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notlike "*Loopback*" -and $_.IPAddress -notlike "169.254*"} | Select-Object -First 1
$ipAddress  = if ($netAdapter) { $netAdapter.IPAddress } else { "No Active Network Connection" }

$pingResult = Test-Connection -TargetName "8.8.8.8" -Count 1 -ErrorAction SilentlyContinue
$latency    = if ($pingResult) { "$($pingResult.Latency) ms" } else { "Host Unreachable" }

# 4. FORMATTED LOG GENERATION
$timeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

$logContent = @"
====================================================
           COMPUTER PULSE - HARDWARE & NETWORK LOG   
====================================================
Timestamp          : $timeStamp
Active Processes   : $processCount running processes
CPU Utilization    : $cpuLoad% load
----------------------------------------------------
Top 3 Memory-Consuming Processes:
$($topProcesses | Out-String)
----------------------------------------------------
Disk Storage Breakdown:
$($disks | Out-String)
----------------------------------------------------
Network Diagnostics:
Active IPv4 Address: $ipAddress
Internet Latency   : $latency (Target: 8.8.8.8)
====================================================
"@

# Ensure output directory exists and write log file
if (-not (Test-Path "data")) {
    New-Item -ItemType Directory -Path "data" | Out-Null
}

$logContent | Out-File -FilePath $LogFile -Encoding utf8

Write-Host "[SUCCESS] Hardware & network diagnostic log saved to $LogFile" -ForegroundColor Green
#