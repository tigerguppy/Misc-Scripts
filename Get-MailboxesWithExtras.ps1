<#
.SYNOPSIS
    Retrieves mailbox information, including forwarding addresses, mailbox rules, and permissions.

.DESCRIPTION
    This function checks Exchange mailboxes for specific properties such as ForwardingSmtpAddress, 
    ForwardingAddress, mailbox rules with forwarding enabled, and additional permissions. 
    It allows output customization (console, file, or object) and supports detailed mailbox 
    processing progress.

.PARAMETER CheckForwardingSmtpAddress
    Checks if a ForwardingSmtpAddress is configured for the mailbox.

.PARAMETER CheckForwardingAddress
    Checks if a ForwardingAddress is configured for the mailbox.

.PARAMETER CheckMailboxRules
    Checks for mailbox rules with forwarding enabled.

.PARAMETER CheckPermissions
    Checks if the mailbox has additional permissions granted to other users.

.PARAMETER CheckAll
    Checks all the options: ForwardingSmtpAddress, ForwardingAddress, Mailbox Rules, and Permissions.

.PARAMETER OutputOption
    Specifies the output method: Console, File, or Object. The default is Object.

.PARAMETER OutputPath
    Specifies the directory to save the output file if 'File' is selected as the output option. 
    Default is the system's Temp directory.

.PARAMETER OutputFileName
    Specifies the name of the output file. If not provided, a timestamped filename is generated.

.EXAMPLE
    Get-MailboxesWithExtras -CheckAll -OutputOption 'File' -OutputPath 'C:\Logs' -OutputFileName 'Mailboxes.txt'
    Retrieves all mailboxes with forwarding and permission information and outputs the result to a file.

.EXAMPLE
    Get-MailboxesWithExtras -CheckForwardingSmtpAddress -OutputOption 'Console'
    Checks mailboxes for ForwardingSmtpAddress and outputs the result to the console.

.NOTES
    Author: Tony Burrows
    Version: 2.1.0 (2024-09-22)
        Added output options
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
            Position = 0, 
            HelpMessage = 'Check all options.', 
            ParameterSetName = 'CheckAll')]
        [switch]$CheckAll = $false,
        
        [Parameter(Mandatory = $False,
            Position = 4,
            HelpMessage = 'Output options.',
            ParameterSetName = 'Default')]
        [Parameter(Mandatory = $False,
            Position = 1,
            HelpMessage = 'Output options.',
            ParameterSetName = 'CheckAll')]
        [ValidateSet('Console', 'File', 'Object')]
        [string]$OutputOption = 'Object',

        [Parameter(Mandatory = $False,
            Position = 5,
            HelpMessage = 'Output path.',
            ParameterSetName = 'Default')]
        [Parameter(Mandatory = $False,
            Position = 2,
            HelpMessage = 'Output path.',
            ParameterSetName = 'CheckAll')]
        [string]$OutputPath = "$env:SystemDrive\Temp",

        [Parameter(Mandatory = $False,
            Position = 6,
            HelpMessage = 'Output filename.',
            ParameterSetName = 'Default')]
        [Parameter(Mandatory = $False,
            Position = 3,
            HelpMessage = 'Output filename.',
            ParameterSetName = 'CheckAll')]
        [string]$OutputFileName = $null
    )

    # Get mailboxes
    $Mailboxes = Get-Mailbox -ResultSize:Unlimited
    $MailboxesQty = $Mailboxes.Count
    $MailboxesCurrentCount = 0

    # New array for returning objects
    [System.Collections.ArrayList]$ReturnList = [System.Collections.ArrayList]::new()

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
                    Description       = $ForwardingSmtpAddress -replace 'smtp:'
                }
                $ReturnList.Add($Obj) | Out-Null
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
                    Description       = $ForwardingAddress -replace 'smtp:'
                }
                $ReturnList.Add($Obj) | Out-Null
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
                        $ReturnList.Add($Obj) | Out-Null
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
                $ReturnList.Add($Obj) | Out-Null
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

    switch ($OutputOption) {
        'Console' { $ReturnList | Sort-Object Description, DisplayName | Format-Table -AutoSize -Wrap }
        'File' {

            # Remove \ if it's at the end of the path
            if ($OutputPath.Trim()[$OutputPath.Length - 1] -eq '\') {
                $OutputPath = $OutputPath.Trim('\')
            }

            if (Test-Path "$OutputPath") {
                # path exists, continuing
            } else {
                try {
                    New-Item -Path "$OutputPath" -ItemType Directory -Force -ErrorAction Stop | Out-Null
                } catch {
                    Write-Output "Unable to create $OutputPath"
                }
            }

            if ($null -eq $OutputFileName) {
                $TimeStamp = $(Get-Date -Format yyyyMMdd-HHmmss)
                $OutputFileName = "Mailboxes-$($TimeStamp).txt"
            }
            
            $OutputFullPath = "$OutputPath\$OutputFileName"

            if (Test-Path "$OutputFullPath") {
                # Path exists, continuing
            } else {
                try {
                    New-Item -Path $OutputPath -Name $OutputFileName -ItemType File -Force -ErrorAction Stop | Out-Null
                } catch {
                    Write-Output "Unable to create $OutputFullPath"
                }
            }

            $ReturnList | Out-File -FilePath "$OutputFullPath"
        }
        'Object' { return $ReturnList }
        Default { return $ReturnList }
    }

} # End Get-MailboxesWithExtras
