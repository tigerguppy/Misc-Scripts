<#
.SYNOPSIS
    Identifies Exchange Online mailboxes with forwarding enabled, mailbox rules with forwarding, or non-default mailbox permissions.

.DESCRIPTION
    This script connects to Exchange Online and checks for mailboxes with forwarding configurations, mailbox rules with forwarding, and additional permissions. It logs the results and disconnects from the session.

.PARAMETER CheckForwardingSmtpAddress
    Checks mailboxes for the `ForwardingSmtpAddress` property.

.PARAMETER CheckForwardingAddress
    Checks mailboxes for the `ForwardingAddress` property.

.PARAMETER CheckMailboxRules
    Checks mailbox rules for forwarding configurations.

.PARAMETER CheckPermissions
    Identifies non-default mailbox permissions.

.PARAMETER CheckAll
    Runs all checks (forwarding, rules, permissions).

.EXAMPLE
    Get-MailboxesWithExtras -CheckAll

.NOTES
    Author: Tony Burrows
    Version: 2.0.0 (2024-09-20)
    Added permission checks and various mailbox-related forwardings.
#>

# Script logic starts here


function Get-MailboxesWithExtras {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory = $false, 
            Position = 0,
            HelpMessage = 'Check mailboxes for ForwardingSmtpAddress.', 
            ParameterSetName = 'Default')]
        [switch]$CheckForwardingSmtpAddress,
        [Parameter(Mandatory = $false, 
            Position = 1,
            HelpMessage = 'Check mailboxes for ForwardingSmtpAddress.', 
            ParameterSetName = 'Default')]
        [switch]$CheckForwardingAddress,
        [Parameter(Mandatory = $false, 
            Position = 2, 
            HelpMessage = 'Check mailboxes for mailbox rules with forwarding enabled.', 
            ParameterSetName = 'Default')]
        [switch]$CheckMailboxRules,
        [Parameter(Mandatory = $false, 
            Position = 3, 
            HelpMessage = 'Check mailboxes for additional permissions.', 
            ParameterSetName = 'Default')]
        [switch]$CheckPermissions = $false,
        [Parameter(Mandatory = $false, 
            Position = 3, 
            HelpMessage = 'Check all options.', 
            ParameterSetName = 'CheckAll')]
        [switch]$CheckAll = $false
    )

    # Get mailboxes
    $Mailboxes = Get-Mailbox -ResultSize:Unlimited
    $MailboxesQty = $Mailboxes.Count
    $MailboxesCurrentCount = 0

    # New array for returning objects
    [System.Collections.ArrayList]$Output = [System.Collections.ArrayList]::new()

    # Walk through each mailbox
    foreach ($Mailbox in $Mailboxes) {

        if ($CheckForwardingSmtpAddress -or $CheckAll) {
            # Check for forwarding set by admins
            $ForwardingSmtpAddress = $Mailbox.ForwardingSmtpAddress
            if ($null -eq $ForwardingSmtpAddress) {
                # ForwardingSmtpAddress not enabled

            } else {
                $Obj = [PSCustomObject]@{
                    DisplayName       = $Mailbox.DisplayName
                    UserPrincipalName = $Mailbox.UserPrincipalName
                    Type              = 'ForwardingSmtpAddress'
                    Description       = $ForwardingSmtpAddress -replace "smtp:"
                }
                $Output.Add($Obj) | Out-Null
            }
        } # End CheckForwardingSmtpAddress

        if ($CheckForwardingAddress -or $CheckAll) {
            $ForwardingAddress = $Mailbox.ForwardingAddress
            if ($null -eq $ForwardingAddress) {
                # ForwardingAddress not enabled

            } else {
                $Obj = [PSCustomObject]@{
                    DisplayName       = $Mailbox.DisplayName
                    UserPrincipalName = $Mailbox.UserPrincipalName
                    Type              = 'ForwardingAddress'
                    Description       = $ForwardingAddress -replace "smtp:"
                }
                $Output.Add($Obj) | Out-Null
            }
        } # End CheckForwardingAddress

        if ($CheckMailboxRules -or $CheckAll) {
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
        } # End CheckMailboxRules

        if ($CheckPermissions -or $CheckAll) {
            # Mailbox permissions that aren't self
            $MailboxPermissions = Get-MailboxPermission -Identity $Mailbox.UserPrincipalName | Where-Object User -Match '@'
            foreach ($MailboxPermission in $MailboxPermissions) {
                $Obj = [PSCustomObject]@{
                    DisplayName       = $Mailbox.DisplayName
                    UserPrincipalName = $Mailbox.UserPrincipalName
                    Type              = 'Permission'
                    Description       = "$($MailboxPermission.User) - $($MailboxPermission.AccessRights)"
                }
                $Output.Add($Obj) | Out-Null
            }
        } # End CheckPermissions

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
} # End Get-MailboxesWithExtras 

Connect-ExchangeOnline
$MailboxesWithExtras = Get-MailboxesWithExtras -CheckAll
Disconnect-ExchangeOnline -Confirm:$false
$MailboxesWithExtras | Sort-Object Description,DisplayName | Format-Table -AutoSize -Wrap
