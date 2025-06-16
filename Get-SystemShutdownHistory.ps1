function Get-SystemShutdownHistory {
    param (
        [Parameter(Mandatory = $true)]
        [int]$Days
    )

    $startTime = (Get-Date).AddDays(-$Days)
    $eventIDs = @(41, 1074, 6005, 6006, 6008)

    Write-Output "Querying shutdown/reboot events for the last $Days day(s)...`n"

    $events = Get-EventLog -LogName System -After $startTime | Where-Object { $eventIDs -contains $_.EventID }
    $events = $events | Sort-Object TimeGenerated

    foreach ($event in $events) {
        $reason = ''
        $details = ''

        switch ($event.EventID) {
            41 {
                $reason = 'Kernel-Power: Crash or unexpected power loss'
                if ($event.Message -match 'BugcheckCode\s*:\s*(\d+)') {
                    $bugcheck = $matches[1]
                } else {
                    $bugcheck = 'Unknown'
                }
                if ($event.Message -match 'PowerButtonTimestamp\s*:\s*(\d+)') {
                    $pwrButton = $matches[1]
                } else {
                    $pwrButton = 'Unknown'
                }
                $details = "BugcheckCode: $bugcheck | PowerButtonTimestamp: $pwrButton"
            }

            6005 {
                $reason = 'System Startup (Event Log Service Started)'
            }

            6006 {
                $reason = 'Clean Shutdown (Event Log Service Stopped)'
            }

            6008 {
                $reason = 'Unexpected Shutdown'
                if ($event.Message -match 'Previous shutdown at (.+?) on') {
                    $shutdownTime = $matches[1]
                } else {
                    $shutdownTime = 'Unknown'
                }
                $details = "Previous shutdown at: $shutdownTime"
            }

            1074 {
                $reason = 'Planned Shutdown/Restart'

                if ($event.Message -match 'The process (.+?) \(') {
                    $process = $matches[1].Trim()
                } else {
                    $process = 'Unknown'
                }

                if ($event.Message -match 'on behalf of user (.+?) for the following reason') {
                    $user = $matches[1].Trim()
                } else {
                    $user = 'Unknown'
                }

                if ($event.Message -match 'for the following reason: (.+?)\s*(Reason Code|Shutdown Type|Comment|$)') {
                    $shutdownReason = $matches[1].Trim()
                } else {
                    $shutdownReason = 'Unknown'
                }

                if ($event.Message -match 'Reason Code:\s+(.+?)\s*(Shutdown Type|Comment|$)') {
                    $reasonCode = $matches[1].Trim()
                } else {
                    $reasonCode = 'Unknown'
                }

                if ($event.Message -match 'Shutdown Type:\s+(.+?)\s*(Comment|$)') {
                    $shutdownType = $matches[1].Trim()
                } else {
                    $shutdownType = 'Unknown'
                }

                if ($event.Message -match 'Comment:\s*(.*)') {
                    $comment = $matches[1].Trim()
                } else {
                    $comment = ''
                }

                $details = "Process: $process | User: $user | Reason: $shutdownReason | ReasonCode: $reasonCode | Type: $shutdownType | Comment: $comment"
            }

            default {
                $reason = 'Other'
            }
        }

        if ($details) {
            Write-Output ('{0} | EventID {1} | {2} | {3}' -f $event.TimeGenerated, $event.EventID, $reason, $details)
        } else {
            Write-Output ('{0} | EventID {1} | {2}' -f $event.TimeGenerated, $event.EventID, $reason)
        }
    }
}
