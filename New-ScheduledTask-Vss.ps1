<#
.SYNOPSIS
Creates a scheduled task to enable system restore and configure periodic Volume Shadow Copies (VSS) snapshots.

.DESCRIPTION
This script enables system restore on the C: drive, sets up shadow storage, enables Task Scheduler logging,
and creates a scheduled task that takes VSS snapshots twice daily at 6:00 AM and 6:00 PM.

.NOTES
Author: Tony Burrows
Date:   March 11, 2025
#>

# Enable System Restore and configure VSS Shadow Storage
Try {
    Enable-ComputerRestore -Drive 'C:' -ErrorAction Stop
    vssadmin resize shadowstorage /for=C: /on=C: /maxsize=20%
    Write-Output "System Restore and Shadow Storage configured successfully."
}
Catch {
    Write-Error "Failed to configure System Restore or Shadow Storage: $_"
    exit 1
}

# Enable Task Scheduler operational logging
Try {
    wevtutil set-log Microsoft-Windows-TaskScheduler/Operational /enabled:true
    Write-Output "Task Scheduler logging enabled."
}
Catch {
    Write-Error "Failed to enable Task Scheduler logging: $_"
}

# Scheduled Task Principal running as SYSTEM
$Principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Task Settings
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

# Scheduled Task triggers (6:00 AM and 6:00 PM daily)
$Triggers = @(
    (New-ScheduledTaskTrigger -Daily -At 6:00AM),
    (New-ScheduledTaskTrigger -Daily -At 6:00PM)
)

# Scheduled Task action to create VSS snapshot
$ScriptBlock = "Get-WmiObject -List Win32_ShadowCopy | ForEach-Object { `$_.Create('C:\\', 'ClientAccessible') }"
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -Command `$($ScriptBlock)"

# Register the Scheduled Task and validate creation
Try {
    $Task = Register-ScheduledTask -TaskName "ShadowCopy_C_6AM_6PM" `
                                   -Trigger $Triggers `
                                   -Action $Action `
                                   -Principal $Principal `
                                   -Settings $Settings `
                                   -Description "Creates VSS snapshots of C drive at 6:00 AM and 6:00 PM daily." `
                                   -ErrorAction Stop

    if ($Task) {
        Write-Output "Scheduled task 'ShadowCopy_C_6AM_6PM' created successfully."
    } else {
        Write-Error "Scheduled task creation returned no object."
    }
}
Catch {
    Write-Error "Failed to create scheduled task 'ShadowCopy_C_6AM_6PM': $_"
}
