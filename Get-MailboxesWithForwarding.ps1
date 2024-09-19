<#
.SYNOPSIS
    Looks for mailboxes with forwarding enabled or mailbox rules with forwarding.
.DESCRIPTION
    Checks for admin forwarding and user rule forwarding in Exchange Online.
.NOTES
    Connects to Exchange Online, gets a list of all the mailboxes, checks them for admin forwarding or Outlook rule forwarding, logs out of Exchange Online, then lists the results.

    Revision history:
        2024-09-18
            Intital release

    To-Do:
        Add parameters to limit what is being searched for.
        Add mailbox permission list for non-default permissions.
            aka, list who has access to the mailbox.
        Run mailboxes in parallel.

.LINK
    https://tony.support/tools

.LINK
    script@tigerguppy.com
    
.EXAMPLE
    Get-MailboxesWithForwarding

.EXAMPLE
    Connect-ExchangeOnline
    $Items = Get-MailboxesWithForwarding
    $Items | Format-Table -AutoSize -Wrap
    Disconnect-ExchangeOnline -Confirm:$false
#>

function Get-MailboxesWithForwarding {

    # Get mailboxes
    $Mailboxes = Get-Mailbox
    $MailboxesQty = $Mailboxes.Count
    $MailboxesCurrentCount = 0

    # New array for returning objects
    [System.Collections.ArrayList]$Output = [System.Collections.ArrayList]::new()

    # Walk through each mailbox
    foreach ($Mailbox in $Mailboxes) {

        # Check for forwarding set by admins
        $ForwardingSmtpAddress = $Mailbox.ForwardingSmtpAddress
        if ($null -eq $ForwardingSmtpAddress) {
            # ForwardingSmtpAddress not enabled

        } else {
            $Obj = [PSCustomObject]@{
                DisplayName       = $Mailbox.DisplayName
                UserPrincipalName = $Mailbox.UserPrincipalName
                Type              = 'ForwardingSmtpAddress'
                Description       = $ForwardingSmtpAddress
            }
            $Output.Add($Obj) | Out-Null
        }

        $ForwardingAddress = $Mailbox.ForwardingAddress
        if ($null -eq $ForwardingAddress) {
            # ForwardingAddress not enabled

        } else {
            $Obj = [PSCustomObject]@{
                DisplayName       = $Mailbox.DisplayName
                UserPrincipalName = $Mailbox.UserPrincipalName
                Type              = 'ForwardingAddress'
                Description       = $ForwardingAddress
            }
            $Output.Add($Obj) | Out-Null
        }

        # Get user's mailbox rules
        $Rules = Get-InboxRule -Mailbox $Mailbox.UserPrincipalName
        $RulesQty = $Rules.Count

        # If there's mailbox rules, add them to the list
        if ($RulesQty -ne 0) {   
            foreach ($Rule in $Rules) {
                if ($null -eq $Rule.ForwardAsAttachmentTo -and $null -eq $Rule.ForwardTo) {
                    # Rule doesn't contain forwarding
                    continue

                } else {
                    $Obj = [PSCustomObject]@{
                        DisplayName       = $Mailbox.DisplayName
                        UserPrincipalName = $Mailbox.UserPrincipalName
                        Type              = 'MailboxRule'
                        Description       = $Rule.Name
                    }
                    $Output.Add($Obj) | Out-Null
                }
            }
        }

        # Update mailboxes progress bar
        $MailboxesCurrentCount ++
        $PercentComplete = ($MailboxesCurrentCount / $MailboxesQty)
        $MailboxProgressParameters = @{
            Id              = 0
            Activity        = 'Mailboxes'
            Status          = "$($PercentComplete.tostring('P')) - $MailboxesCurrentCount / $MailboxesQty - $($Mailbox.UserPrincipalName)"
            PercentComplete = $PercentComplete * 100
        }
        Write-Progress @MailboxProgressParameters

    } # End mailbox loop

    # Function clean up
    Write-Progress -Id 0 -Activity 'Mailboxes' -Completed
    return $Output
} # End Get-MailboxesWithForwarding

Connect-ExchangeOnline
$ForwardingItems = Get-MailboxesWithForwarding
Disconnect-ExchangeOnline -Confirm:$false

$ForwardingItems | Format-Table -AutoSize -Wrap
