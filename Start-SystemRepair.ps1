<#
.SYNOPSIS
    Comprehensive Windows troubleshooting and repair script.
.DESCRIPTION
    Automates filesystem corruption checks, Windows Update component resets,
    network resets, malware scans, and autorun/scheduled tasks reviews. Logs actions with timestamps.
.NOTES
    Author: Tony Burrows
    Date: 2024-03-11
#>

# Ensure administrative privileges
function Test-AdminPrivilege {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole] 'Administrator')) {
        Write-Warning 'This script must be run as Administrator.'
        exit
    }
}

# Log Directory
function Initialize-LogDirectory {
    $LogDir = "$env:SystemDrive\RepairLogs"
    New-Item -Path $LogDir -ItemType Directory -Force | Out-Null
    return $LogDir
}

# Function: Write Log Entry
function Write-LogEntry($Message, $LogFile, $LogDir) {
    $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    "$Timestamp - $Message" | Out-File -FilePath "$LogDir\$LogFile" -Append
}

# OS Version Check
function Get-OSVersion($LogDir) {
    $OSVersion = (Get-CimInstance Win32_OperatingSystem).Caption
    Write-LogEntry "Operating System: $OSVersion" 'Summary.log' $LogDir
}

# Disk Space Check
function Test-DiskSpace($LogDir) {
    $FreeSpaceGB = (Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'").FreeSpace / 1GB
    if ($FreeSpaceGB -lt 5) {
        Write-Warning 'Less than 5 GB free on C: drive. Script cannot continue.'
        Write-LogEntry "Insufficient disk space: $([math]::Round($FreeSpaceGB,2)) GB free." 'DiskSpace.log' $LogDir
        exit
    }
}

# User Confirmation
function Get-UserConsent($LogDir) {
    $UserConsent = Read-Host 'This script performs major system repairs. Continue? (Y/N)'
    if ($UserConsent -notin @('Y', 'y')) {
        Write-Warning 'Script execution aborted by user.'
        Write-LogEntry 'Execution aborted by user.' 'Summary.log' $LogDir
        exit
    }
}

# Create Restore Point
function New-SystemRestorePoint($LogDir) {
    Write-Host 'Creating System Restore Point...'
    try {
        Checkpoint-Computer -Description 'System Repair Restore Point' -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop
        Write-LogEntry 'System Restore Point created.' 'RestorePoint.log' $LogDir
    } catch {
        Write-Warning "Failed to create System Restore Point: $($_.Exception.Message)"
        Write-LogEntry "Restore Point creation failed: $($_.Exception.Message)" 'RestorePoint.log' $LogDir
    }
}

# Invoke Command with Logging
function Invoke-LoggedCommand($Command, $Arguments, $LogName, $LogDir) {
    Write-Host "Running: $($Command) $($Arguments):"
    try {
        Start-Process -FilePath $Command -ArgumentList $Arguments -Wait -NoNewWindow -RedirectStandardOutput "$LogDir\$LogName.log" -RedirectStandardError "$LogDir\$LogName-errors.log" -ErrorAction Stop
        Write-LogEntry "$Command $Arguments completed." "$LogName.log" $LogDir
    } catch {
        Write-Warning "Failed to execute $($Command) $($Arguments): $($_.Exception.Message)"
        Write-LogEntry "Failed: $($Command) $($Arguments): $($_.Exception.Message)" "$LogName.log" $LogDir
    }
}

# Perform Corruption Checks
function Invoke-CorruptionChecks($LogDir) {
    Invoke-LoggedCommand 'chkdsk' '/scan /perf' 'CHKDSK' $LogDir
    Invoke-LoggedCommand 'sfc' '/scannow' 'SFC_FirstScan' $LogDir
    Invoke-LoggedCommand 'DISM' '/Online /Cleanup-Image /RestoreHealth' 'DISM' $LogDir
    Invoke-LoggedCommand 'sfc' '/scannow' 'SFC_SecondScan' $LogDir
}

# Reset Windows Update Components
function Reset-WindowsUpdate($LogDir) {
    $services = @('BITS', 'wuauserv', 'appidsvc', 'cryptsvc')
    foreach ($svc in $services) {
        try {
            Stop-Service -Name $svc -Force -ErrorAction Stop
            Write-LogEntry "$($svc) stopped." 'WindowsUpdate.log' $LogDir
        } catch {
            Write-Warning "Failed to stop $($svc): $($_.Exception.Message)"
            Write-LogEntry "Failed to stop $($svc): $($_.Exception.Message)" 'WindowsUpdate.log' $LogDir
        }
    }

    try {
        Remove-Item "$env:allusersprofile\Application Data\Microsoft\Network\Downloader\qmgr*.dat" -ErrorAction Stop
        Rename-Item "$env:systemroot\SoftwareDistribution\DataStore" 'DataStore.bak' -ErrorAction Stop
        Rename-Item "$env:systemroot\System32\Catroot2" 'catroot2.bak' -ErrorAction Stop
        Rename-Item "$env:systemroot\SoftwareDistribution\Download" 'Download.bak' -ErrorAction Stop
        Remove-Item "$env:systemroot\WindowsUpdate.log" -ErrorAction Stop
        Write-LogEntry 'Windows Update folders and logs reset.' 'WindowsUpdate.log' $LogDir
    } catch {
        Write-Warning "Windows Update reset error: $($_.Exception.Message)"
        Write-LogEntry "Windows Update reset error: $($_.Exception.Message)" 'WindowsUpdate.log' $LogDir
    }

    foreach ($svc in $services) {
        Set-Service $svc -StartupType Manual
        Start-Service $svc
    }
    wuauclt /resetauthorization /detectnow
}

# Network Resets
function Reset-Network($LogDir) {
    Invoke-LoggedCommand 'netsh' 'winsock reset' 'NetworkReset' $LogDir
    Invoke-LoggedCommand 'netsh' 'int ip reset' 'NetworkReset' $LogDir
    Invoke-LoggedCommand 'ipconfig' '/flushdns' 'NetworkReset' $LogDir
}

# Malware Scan
function Invoke-MalwareScan($LogDir) {
    Invoke-LoggedCommand 'powershell' 'Start-MpScan -ScanType QuickScan' 'MalwareScan' $LogDir
}

# Scheduled Tasks & Autoruns
function Review-SystemTasks($LogDir) {
    Get-ScheduledTask | Where-Object { $_.State -eq 'Ready' } | Select-Object TaskName, State | Out-File "$LogDir\ScheduledTasks.log"
    Write-LogEntry 'Scheduled tasks reviewed.' 'ScheduledTasks.log' $LogDir

    Get-CimInstance Win32_StartupCommand | Select-Object Name, Command, Location | Out-File "$LogDir\Autoruns.log"
    Write-LogEntry 'Autorun entries reviewed.' 'Autoruns.log' $LogDir
}

# Main Execution
Test-AdminPrivilege
$LogDir = Initialize-LogDirectory
Write-LogEntry 'Script execution started.' 'Summary.log' $LogDir
Get-OSVersion $LogDir
Test-DiskSpace $LogDir
Get-UserConsent $LogDir
New-SystemRestorePoint $LogDir
Invoke-CorruptionChecks $LogDir
Reset-WindowsUpdate $LogDir
Reset-Network $LogDir
Invoke-MalwareScan $LogDir
Review-SystemTasks $LogDir

# Completion
$EndTime = Get-Date
$TotalDuration = $EndTime - $StartTime
Write-LogEntry "Script completed. Duration: $TotalDuration" 'Summary.log' $LogDir
Write-Host "All operations completed. Logs saved at $LogDir"
Write-Host 'Please reboot your computer to finalize repairs.'
