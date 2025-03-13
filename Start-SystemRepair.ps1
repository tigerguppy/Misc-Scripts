<#
.SYNOPSIS
    Comprehensive Windows troubleshooting and repair script.
.DESCRIPTION
    Automates filesystem corruption checks, Windows Update component resets,
    network resets, malware scans, and autorun/scheduled tasks reviews. Logs actions with timestamps,
    shows progress, tees outputs to both the console and log files, and captures a transcript.
.NOTES
    Author: Tony Burrows
    Date: 2025-03-12
#>

# Global variables for progress tracking
$global:StepCounter = 0
$global:TotalSteps = 22  # NOTE: Update this variable if the number of steps changes.
$GLOBAL:OriginalConsoleMode = $null

function Disable-QuickEdit {
    <#
    .SYNOPSIS
        Disables QuickEdit mode in the PowerShell console.
    .DESCRIPTION
        Retrieves the current console mode and disables QuickEdit mode by removing
        the ENABLE_QUICK_EDIT_MODE flag. Prevents script execution from pausing
        when the window is clicked.
    .NOTES
        QuickEdit mode allows users to click inside the console window and select text,
        but it also pauses script execution until selection is cleared.
    .EXAMPLE
        Disable-QuickEdit
        Disables QuickEdit mode in the active PowerShell session.
    #>
    Add-Type -MemberDefinition @'
        [DllImport("kernel32.dll", SetLastError=true)]
        public static extern IntPtr GetStdHandle(int nStdHandle);
        [DllImport("kernel32.dll", SetLastError=true)]
        public static extern bool GetConsoleMode(IntPtr hConsoleHandle, out int lpMode);
        [DllImport("kernel32.dll", SetLastError=true)]
        public static extern bool SetConsoleMode(IntPtr hConsoleHandle, int dwMode);
'@ -Name 'Kernel32' -Namespace 'WinAPI'

    $STD_INPUT_HANDLE = -10  # Standard input handle
    $hInput = [WinAPI.Kernel32]::GetStdHandle($STD_INPUT_HANDLE)

    if ($hInput -eq [IntPtr]::Zero) { return }

    $mode = 0
    if ([WinAPI.Kernel32]::GetConsoleMode($hInput, [ref]$mode)) {
        $GLOBAL:OriginalConsoleMode = $mode  
        $newMode = $mode -band (-bnot 0x40)  # Disable QuickEdit Mode (mask out ENABLE_QUICK_EDIT_MODE 0x40)
        [WinAPI.Kernel32]::SetConsoleMode($hInput, $newMode) | Out-Null
    }
}

function Enable-QuickEdit {
    <#
    .SYNOPSIS
        Restores QuickEdit mode in the PowerShell console.
    .DESCRIPTION
        Restores the console mode settings to their original state before QuickEdit mode
        was disabled.
    .NOTES
        This function should be executed when the script exits to ensure the console
        behaves as expected for the user.
    .EXAMPLE
        Enable-QuickEdit
        Restores QuickEdit mode in the active PowerShell session.
    #>
    if ($null -ne $GLOBAL:OriginalConsoleMode) {
        $STD_INPUT_HANDLE = -10
        $hInput = [WinAPI.Kernel32]::GetStdHandle($STD_INPUT_HANDLE)
        [WinAPI.Kernel32]::SetConsoleMode($hInput, $GLOBAL:OriginalConsoleMode) | Out-Null
    }
}

function Set-WindowMaximized {
    $hwnd = (Get-Process -Id $PID).MainWindowHandle
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

    $SW_MAXIMIZE = 3
    if ($hwnd -eq [IntPtr]::Zero) {
        $hwnd = [CustomWinAPI.WindowHelper]::GetForegroundWindow()
    }
    if ($hwnd -eq [IntPtr]::Zero) {
        Write-Warning 'Unable to locate a valid window handle.'
        return
    }
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
    $MessageToLog | Out-File -FilePath "$LogDir\$LogFile" -Append
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
                Enable-ComputerRestore -Drive 'C:\' -ErrorAction Stop
                Write-StepLogEntry -Message 'System Restore enabled for C:\' -LogFile 'RestorePoint.log' -LogDir $LogDir
                Set-Service -Name VSS -StartupType Automatic -ErrorAction Stop
                Start-Service -Name VSS -ErrorAction Stop
                Write-StepLogEntry -Message 'Volume Shadow Copy service started.' -LogFile 'RestorePoint.log' -LogDir $LogDir
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
Disable-QuickEdit

# Ensure QuickEdit is restored when script exits, even if terminated
Register-EngineEvent PowerShell.Exiting -Action { Enable-QuickEdit }

try {
    $global:StartTime = Get-Date  # Initialize start time here
    $LogDir = Initialize-LogDirectory

    # Start transcript logging (saved in the same log folder)
    Start-Transcript -Path "$LogDir\Transcript.log" -Append

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

    $EndTime = Get-Date
    $TotalDuration = $EndTime - $global:StartTime
    Write-StepLogEntry -Message "Script completed. Duration: $TotalDuration" -LogFile 'Summary.log' -LogDir $LogDir
    Write-Host "All operations completed. Logs saved at $LogDir"
    Write-Host 'Please reboot your computer to finalize repairs.'
} catch {
    Write-Warning "An unexpected error occurred: $_"
} finally {
    Enable-QuickEdit  # Re-enable QuickEdit before exit
    Stop-Transcript   # Ensure transcript is stopped
}
