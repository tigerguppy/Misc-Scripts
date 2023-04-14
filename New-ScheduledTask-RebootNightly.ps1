Write-Output 'Configure scheduled task'
wevtutil Set-Log Microsoft-Windows-TaskScheduler/Operational /enabled:true # enable scheduled task history
$Task_Name = 'Restart Computer'
$Task_Path = 'Admin'
$Task_Action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument 'shutdown.exe /r /t 0 /f'
$Task_Trigger = New-ScheduledTaskTrigger -Daily -At '4:00 AM'
$Task_Principal = New-ScheduledTaskPrincipal -RunLevel Highest -UserId 'SYSTEM'
$Task_Settings = New-ScheduledTaskSettingsSet -MultipleInstances:IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Hours 1)
$Task_Task = New-ScheduledTask -Action $Task_Action -Principal $Task_Principal -Trigger $Task_Trigger -Settings $Task_Settings
Register-ScheduledTask -TaskName $Task_Name -TaskPath $Task_Path -InputObject $Task_Task