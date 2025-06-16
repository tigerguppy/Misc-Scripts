function Get-SystemShutdownHistory {
    param (
        [Parameter(Mandatory=$true)]
        [int]$Days
    )

    $startTime = (Get-Date).AddDays(-$Days)
    $eventIDs = @(41, 6005, 6006, 6008, 1074)

    Write-Output "Querying shutdown/reboot events for the last $Days day(s)...`n"

    $events = Get-EventLog -LogName System -After $startTime | Where-Object { $eventIDs -contains $_.EventID }
    $events = $events | Sort-Object TimeGenerated

    foreach ($event in $events) {
        $reason = ""
        $details = @{}

        switch ($event.EventID) {
            41 {
                $reason = "Kernel-Power: Crash or unexpected power loss"
                if ($event.Message -match "BugcheckCode\s*:\s*(\d+)") {
                    $details["BugcheckCode"] = $matches[1]
                } else {
                    $details["BugcheckCode"] = "Unknown"
                }
                if ($event.Message -match "PowerButtonTimestamp\s*:\s*(\d+)") {
                    $details["PowerButtonTimestamp"] = $matches[1]
                } else {
                    $details["PowerButtonTimestamp"] = "Unknown"
                }
            }

            6005 {
                $reason = "System Startup (Event Log Service Started)"
            }

            6006 {
                $reason = "Clean Shutdown (Event Log Service Stopped)"
            }

            6008 {
                $reason = "Unexpected Shutdown"
                if ($event.Message -match "Previous shutdown at (.+?) on") {
                    $details["PreviousShutdownAt"] = $matches[1]
                } else {
                    $details["PreviousShutdownAt"] = "Unknown"
                }
            }

            1074 {
                $reason = "Planned Shutdown/Restart"

                if ($event.Message -match "The process (.+?) \(") {
                    $details["Process"] = $matches[1].Trim()
                } else {
                    $details["Process"] = "Unknown"
                }

                if ($event.Message -match "on behalf of user (.+?) for the following reason") {
                    $details["User"] = $matches[1].Trim()
                } else {
                    $details["User"] = "Unknown"
                }

                if ($event.Message -match "for the following reason: (.+?)\s*(Reason Code|Shutdown Type|Comment|$)") {
                    $details["Reason"] = $matches[1].Trim()
                } else {
                    $details["Reason"] = "Unknown"
                }

                if ($event.Message -match "Reason Code:\s+(.+?)\s*(Shutdown Type|Comment|$)") {
                    $details["ReasonCode"] = $matches[1].Trim()
                } else {
                    $details["ReasonCode"] = "Unknown"
                }

                if ($event.Message -match "Shutdown Type:\s+(.+?)\s*(Comment|$)") {
                    $details["ShutdownType"] = $matches[1].Trim()
                } else {
                    $details["ShutdownType"] = "Unknown"
                }

                if ($event.Message -match "Comment:\s*(.*)") {
                    $details["Comment"] = $matches[1].Trim()
                } else {
                    $details["Comment"] = ""
                }
            }

            default {
                $reason = "Other"
            }
        }

        # Output formatting
        Write-Output ("Time: {0}" -f $event.TimeGenerated)
        Write-Output ("EventID: {0}" -f $event.EventID)
        Write-Output ("Type: {0}" -f $reason)

        foreach ($key in $details.Keys) {
            Write-Output ("{0}: {1}" -f $key, $details[$key])
        }

        Write-Output "`n--------------------------------------`n"
    }
}

Get-SystemShutdownHistory -Days 30

Read-Host "Press Enter to Exit"
exit
