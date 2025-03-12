<#
.SYNOPSIS
    Comprehensive Windows troubleshooting and repair script.
.DESCRIPTION
    Automates filesystem corruption checks, Windows Update component resets,
    network resets, malware scans, and autorun/scheduled tasks reviews. Logs actions with timestamps,
    shows progress, and tees outputs to both the console and log files.
.NOTES
    Author: Tony Burrows
    Date: 2025-03-11
#>

# Global variables for progress tracking
$global:StepCounter = 0
$global:TotalSteps = 22

function Set-WindowMaximized {
    # Attempt to retrieve the main window handle for the current process.
    $hwnd = (Get-Process -Id $PID).MainWindowHandle

    # Add the necessary user32.dll functions.
    # The namespace is declared within the type definition.
    Add-Type -TypeDefinition @'
namespace CustomWinAPI {
    using System;
    using System.Runtime.InteropServices;
    public static class WindowHelper {
        [DllImport("user32.dll")]
        public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
        [DllImport("user32.dll")]
        public static extern IntPtr GetForegroundWindow();
    }
}
'@ -ErrorAction Stop

    # SW_MAXIMIZE constant (3)
    $SW_MAXIMIZE = 3

    # If no main window handle is found (common in Windows Terminal),
    # fall back to using the current foreground window.
    if ($hwnd -eq [IntPtr]::Zero) {
        $hwnd = [CustomWinAPI.WindowHelper]::GetForegroundWindow()
    }

    if ($hwnd -eq [IntPtr]::Zero) {
        Write-Warning 'Unable to locate a valid window handle.'
        return
    }

    # Maximize the window using the ShowWindow API.
    [CustomWinAPI.WindowHelper]::ShowWindow($hwnd, $SW_MAXIMIZE) | Out-Null
}

# Helper: Update progress bar
function Update-Progress {
    param(
        [int]$Step,
        [int]$Total,
        [string]$Activity
    )
    $Percent = [math]::Round(($Step / $Total) * 100, 0)
    if ($Percent -gt 100) { $Percent = 100 }
    Write-Progress -Activity $Activity -Status "Step $Step of $Total ($Percent`%)" -PercentComplete $Percent
}

# Tee output function: writes message to both log file and console
function Write-LogEntry {
    param (
        [string]$Message,
        [string]$LogFile,
        [string]$LogDir,
        [int]$StepNumber = $null
    )
    $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    if ($StepNumber -ne $null) {
        $MessageToLog = "[$( 'Step ' + $StepNumber )] $Timestamp - $Message"
    } else {
        $MessageToLog = "$Timestamp - $Message"
    }
    # Write to log file
    $MessageToLog | Out-File -FilePath "$LogDir\$LogFile" -Append
    # Also output to the console
    Write-Host $MessageToLog
}

# Helper: Increment step counter and log with step indicator
function Write-StepLogEntry {
    param (
        [string]$Message,
        [string]$LogFile,
        [string]$LogDir
    )
    $global:StepCounter++
    Write-LogEntry -Message $Message -LogFile $LogFile -LogDir $LogDir -StepNumber $global:StepCounter
    # Update progress bar after logging each major step
    Update-Progress -Step $global:StepCounter -Total $global:TotalSteps -Activity 'Executing Steps'
}

# Ensure administrative privileges
function Test-AdminPrivilege {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole] 'Administrator')) {
        Write-Warning 'This script must be run as Administrator.'
        exit
    }
}

# Create a unique log directory for this run (timestamped)
function Initialize-LogDirectory {
    $BaseLogDir = "$env:SystemDrive\RepairLogs"
    if (-not (Test-Path $BaseLogDir)) {
        New-Item -Path $BaseLogDir -ItemType Directory -Force | Out-Null
    }
    $TimeStamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $UniqueLogDir = Join-Path -Path $BaseLogDir -ChildPath $TimeStamp
    New-Item -Path $UniqueLogDir -ItemType Directory -Force | Out-Null
    return $UniqueLogDir
}

# OS Version Check
function Get-OSVersion {
    param([string]$LogDir)
    $OSVersion = (Get-CimInstance Win32_OperatingSystem).Caption
    Write-StepLogEntry -Message "Operating System: $OSVersion" -LogFile 'Summary.log' -LogDir $LogDir
}

# Disk Space Check
function Test-DiskSpace {
    param([string]$LogDir)
    $FreeSpaceGB = (Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'").FreeSpace / 1GB
    if ($FreeSpaceGB -lt 5) {
        $msg = "Less than 5 GB free on C: drive. Script cannot continue. Only $([math]::Round($FreeSpaceGB,2)) GB free."
        Write-Warning $msg
        Write-StepLogEntry -Message $msg -LogFile 'DiskSpace.log' -LogDir $LogDir
        exit
    }
    Write-StepLogEntry -Message "Disk space check passed. Free space: $([math]::Round($FreeSpaceGB,2)) GB." -LogFile 'DiskSpace.log' -LogDir $LogDir
}

# User Confirmation
function Get-UserConsent {
    param([string]$LogDir)
    $UserConsent = Read-Host 'This script performs major system repairs. Continue? (Y/N)'
    if ($UserConsent -notin @('Y', 'y')) {
        Write-Warning 'Script execution aborted by user.'
        Write-StepLogEntry -Message 'Execution aborted by user.' -LogFile 'Summary.log' -LogDir $LogDir
        exit
    }
    Write-StepLogEntry -Message 'User consent received. Continuing.' -LogFile 'Summary.log' -LogDir $LogDir
}

# Create Restore Point with repair attempt if needed
function New-SystemRestorePoint {
    param([string]$LogDir)
    Write-Host 'Creating System Restore Point...'
    try {
        Checkpoint-Computer -Description 'System Repair Restore Point' -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop
        Write-StepLogEntry -Message 'System Restore Point created.' -LogFile 'RestorePoint.log' -LogDir $LogDir
    } catch {
        $errMsg = "Failed to create System Restore Point: $($_.Exception.Message)"
        Write-Warning $errMsg
        Write-StepLogEntry -Message $errMsg -LogFile 'RestorePoint.log' -LogDir $LogDir
        
        $userResponse = Read-Host 'Would you like to attempt to repair the system restore configuration and try again? (Y/N)'
        if ($userResponse -match '^[Yy]$') {
            try {
                Write-Host 'Attempting to repair system restore configuration...'
                Write-StepLogEntry -Message 'Attempting to repair system restore configuration.' -LogFile 'RestorePoint.log' -LogDir $LogDir
                
                # Enable System Restore for C: drive if disabled
                Enable-ComputerRestore -Drive 'C:\' -ErrorAction Stop
                Write-StepLogEntry -Message 'System Restore enabled for C:\' -LogFile 'RestorePoint.log' -LogDir $LogDir
                
                # Ensure Volume Shadow Copy service is set to Automatic and start it
                Set-Service -Name VSS -StartupType Automatic -ErrorAction Stop
                Start-Service -Name VSS -ErrorAction Stop
                Write-StepLogEntry -Message 'Volume Shadow Copy service started.' -LogFile 'RestorePoint.log' -LogDir $LogDir
                
                # Attempt to create the restore point again
                Checkpoint-Computer -Description 'System Repair Restore Point' -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop
                Write-StepLogEntry -Message 'System Restore Point created on second attempt.' -LogFile 'RestorePoint.log' -LogDir $LogDir
            } catch {
                $errMsg2 = "Second attempt to create System Restore Point failed: $($_.Exception.Message)"
                Write-Warning $errMsg2
                Write-StepLogEntry -Message $errMsg2 -LogFile 'RestorePoint.log' -LogDir $LogDir
            }
        } else {
            Write-StepLogEntry -Message 'User chose not to attempt repair of System Restore.' -LogFile 'RestorePoint.log' -LogDir $LogDir
        }
    }
}

# Invoke Command with Logging
function Invoke-LoggedCommand {
    param(
        [string]$Command,
        [string]$Arguments,
        [string]$LogName,
        [string]$LogDir
    )
    Write-Host "Running: $Command $Arguments"
    try {
        Start-Process -FilePath $Command -ArgumentList $Arguments -Wait -NoNewWindow `
            -RedirectStandardOutput "$LogDir\$LogName.log" `
            -RedirectStandardError "$LogDir\$LogName-errors.log" -ErrorAction Stop
        Write-StepLogEntry -Message "$Command $Arguments completed." -LogFile "$LogName.log" -LogDir $LogDir
    } catch {
        $errMsg = "Failed to execute $Command $($Arguments): $($_.Exception.Message)"
        Write-Warning $errMsg
        Write-StepLogEntry -Message $errMsg -LogFile "$LogName.log" -LogDir $LogDir
    }
}

# Perform Corruption Checks
function Invoke-CorruptionChecks {
    param([string]$LogDir)
    Invoke-LoggedCommand -Command 'chkdsk' -Arguments '/scan /perf' -LogName 'CHKDSK' -LogDir $LogDir
    Invoke-LoggedCommand -Command 'sfc' -Arguments '/scannow' -LogName 'SFC_FirstScan' -LogDir $LogDir
    Invoke-LoggedCommand -Command 'DISM' -Arguments '/Online /Cleanup-Image /RestoreHealth' -LogName 'DISM' -LogDir $LogDir
    Invoke-LoggedCommand -Command 'sfc' -Arguments '/scannow' -LogName 'SFC_SecondScan' -LogDir $LogDir
}

# Reset Windows Update Components
function Reset-WindowsUpdate {
    param([string]$LogDir)
    $services = @('BITS', 'wuauserv', 'appidsvc', 'cryptsvc')
    foreach ($svc in $services) {
        try {
            Stop-Service -Name $svc -Force -ErrorAction Stop
            Write-StepLogEntry -Message "$svc stopped." -LogFile 'WindowsUpdate.log' -LogDir $LogDir
        } catch {
            $errMsg = "Failed to stop $($svc): $($_.Exception.Message)"
            Write-Warning $errMsg
            Write-StepLogEntry -Message $errMsg -LogFile 'WindowsUpdate.log' -LogDir $LogDir
        }
    }

    try {
        Remove-Item "$env:allusersprofile`:\Application Data\Microsoft\Network\Downloader\qmgr*.dat" -ErrorAction Stop
        Rename-Item "$env:systemroot`:\SoftwareDistribution\DataStore" 'DataStore.bak' -ErrorAction Stop
        Rename-Item "$env:systemroot`:\System32\Catroot2" 'catroot2.bak' -ErrorAction Stop
        Rename-Item "$env:systemroot`:\SoftwareDistribution\Download" 'Download.bak' -ErrorAction Stop
        Remove-Item "$env:systemroot`:\WindowsUpdate.log" -ErrorAction Stop
        Write-StepLogEntry -Message 'Windows Update folders and logs reset.' -LogFile 'WindowsUpdate.log' -LogDir $LogDir
    } catch {
        $errMsg = "Windows Update reset error: $($_.Exception.Message)"
        Write-Warning $errMsg
        Write-StepLogEntry -Message $errMsg -LogFile 'WindowsUpdate.log' -LogDir $LogDir
    }

    foreach ($svc in $services) {
        # Skip reconfiguring 'appidsvc' due to known access restrictions.
        if ($svc -eq 'appidsvc') {
            $skipMsg = "Skipping reconfiguration for $svc due to access restrictions."
            Write-StepLogEntry -Message $skipMsg -LogFile 'WindowsUpdate.log' -LogDir $LogDir
            continue
        }
        try {
            Set-Service $svc -StartupType Manual -ErrorAction Stop
            Start-Service $svc -ErrorAction Stop
        } catch {
            $errMsg = "Failed to reconfigure $($svc): $($_.Exception.Message)"
            Write-Warning $errMsg
            Write-StepLogEntry -Message $errMsg -LogFile 'WindowsUpdate.log' -LogDir $LogDir
        }
    }
    wuauclt /resetauthorization /detectnow
}

# Network Resets
function Reset-Network {
    param([string]$LogDir)
    Invoke-LoggedCommand -Command 'netsh' -Arguments 'winsock reset' -LogName 'NetworkReset' -LogDir $LogDir
    Invoke-LoggedCommand -Command 'netsh' -Arguments 'int ip reset' -LogName 'NetworkReset' -LogDir $LogDir
    Invoke-LoggedCommand -Command 'ipconfig' -Arguments '/flushdns' -LogName 'NetworkReset' -LogDir $LogDir
}

# Malware Scan
function Invoke-MalwareScan {
    param([string]$LogDir)
    Invoke-LoggedCommand -Command 'powershell' -Arguments 'Start-MpScan -ScanType QuickScan' -LogName 'MalwareScan' -LogDir $LogDir
}

# Scheduled Tasks & Autoruns
function Get-SystemTasks {
    param([string]$LogDir)
    Get-ScheduledTask | Where-Object { $_.State -eq 'Ready' } | Select-Object TaskName, State | Out-File "$LogDir\ScheduledTasks.log"
    Write-StepLogEntry -Message 'Scheduled tasks reviewed.' -LogFile 'ScheduledTasks.log' -LogDir $LogDir

    Get-CimInstance Win32_StartupCommand | Select-Object Name, Command, Location | Out-File "$LogDir\Autoruns.log"
    Write-StepLogEntry -Message 'Autorun entries reviewed.' -LogFile 'Autoruns.log' -LogDir $LogDir
}

# Main Execution
Test-AdminPrivilege
Set-WindowMaximized

$global:StartTime = Get-Date  # Initialize start time here
$LogDir = Initialize-LogDirectory
Write-StepLogEntry -Message 'Script execution started.' -LogFile 'Summary.log' -LogDir $LogDir

Get-OSVersion -LogDir $LogDir
Test-DiskSpace -LogDir $LogDir
Get-UserConsent -LogDir $LogDir
New-SystemRestorePoint -LogDir $LogDir
Invoke-CorruptionChecks -LogDir $LogDir
Reset-WindowsUpdate -LogDir $LogDir
Reset-Network -LogDir $LogDir
Invoke-MalwareScan -LogDir $LogDir
Get-SystemTasks -LogDir $LogDir

# Completion
$EndTime = Get-Date
$TotalDuration = $EndTime - $global:StartTime
Write-StepLogEntry -Message "Script completed. Duration: $TotalDuration" -LogFile 'Summary.log' -LogDir $LogDir
Write-Host "All operations completed. Logs saved at $LogDir"
Write-Host 'Please reboot your computer to finalize repairs.'
