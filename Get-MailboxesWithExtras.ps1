<#
.SYNOPSIS
    Looks for mailboxes with forwarding enabled or mailbox rules with forwarding or mailboxes with extra permissions in Exchange Online.
.DESCRIPTION
    Looks for mailboxes with forwarding enabled or mailbox rules with forwarding or mailboxes with extra permissions in Exchange Online.
.NOTES
    Assumes ExchangeOnline module is already installed and you're connected to EXO.
    Connects to Exchange Online, gets a list of all the mailboxes, checks them for admin forwarding or Outlook rule forwarding, logs out of Exchange Online, then lists the results.

    Revision history:
        2024-09-18
            Intital release
        2024-09-19
            Add mailbox permission list for non-default permissions.
            Add parameters to limit what is being searched for.

    To-Do:
        Run mailboxes in parallel.

.LINK
    https://github.com/tigerguppy/Misc-Scripts/edit/main/Get-MailboxesWithExtras.ps1

.EXAMPLE
    Get-MailboxesWithExtras -CheckForwardingSmtpAddress -CheckMailboxRules

.EXAMPLE
    Get-MailboxesWithExtras -CheckAll

.EXAMPLE
    Connect-ExchangeOnline
    $ForwardingItems = Get-MailboxesWithExtras -CheckAll
    $Items | Format-Table -AutoSize -Wrap
    Disconnect-ExchangeOnline -Confirm:$false

.PARAMETER CheckForwardingSmtpAddress
    Check mailboxes for ForwardingSmtpAddress.

.PARAMETER CheckForwardingAddress
    Check mailboxes for ForwardingSmtpAddress.

.PARAMETER CheckMailboxRules
    Check mailboxes for mailbox rules with forwarding enabled.

.PARAMETER CheckPermissions
    Check mailboxes for additional permissions.

.PARAMETER CheckAll
    Check all tests.

.AUTHOR
    Tony Burrows
    script@tigerguppy.com
#>

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
