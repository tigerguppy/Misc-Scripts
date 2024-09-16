#requires -version 5

Import-Module ActiveDirectory

<#
.SYNOPSIS
    This script is meant to easily pull select and unsecure information from Active Directory.

.DESCRIPTION
    This script is meant to easily pull select and unsecure information from Active Directory.

.NOTES
    Additional information about the function or script.
    Name: Get-UserInfo
    Author: Tony Burrows
    Contact: scripts@tigerguppy.com

    VERSION HISTORY
        Created on 2021-04-19
        Version 1.0 2021-04-19
            Initial release
        Version 1.1 2021-04-20
            Updated to dynamically pull AD info without hardcoded variables.
        Version 1.2 2021-04-23
            Remove DLL option to load AD module. Use this method instead if RSAT isn't installed.
            https://petertheautomator.com/2020/10/05/use-the-active-directory-powershell-module-without-installing-rsat/
            Copy ActiveDirectory folder to 'C:\Windows\System32\WindowsPowerShell\v1.0\Modules'
        Version 1.3 2021-04-23
            Added a couple attributes to the output.
            Filtered out admin and test accounts.
        Version 1.4 2021-05-07
            Added option to list all users.
            Added sort by date user was created.
        Version 1.5 2021-05-11
            List groups when querying individual user
		Version 1.5.1 2021-05-27
			Changed default sort
		Version 1.5.2 2021-12-11
			Added IPPhone
        Version 1.5.3 2022-02-15
            Add exit command
        Version 1.5.4 2022-02-16
            Add description and WhenChanged fields to output.
		Version 1.5.5 2022-02-28
			Fixed exit so it does not query AD before exiting.
        Version 1.6.0 2022-03-02
            Turn script into a function
            Add option to not show security groups
        Version 1.7.0 2022-04-18
            Change search to return custom PSObject
            Remove "show security groups" option
        Version 2.0.0 2023-08-11
            Add list of user groups for individual user lookups
            Removed bulk listing option due to restructure of script and changing its overall purpose
            Changed output from objects to console text
        Version 2.0.1 2023-08-16
            Add PasswordExpired & SamAccountName to output
        Version 2.0.2 2023-08-23
            Add extensionAttributes
            Changed UserProperties to an ArrayList
        Version 2.0.3 2024-09-16
            Add BadPwdCount, LastBadPasswordAttempt, & PwdLastSet attributes
            Add options to specifiy a domain controller and/or DistinguishedName

.EXAMPLE
    Get-UserInfo

.INPUTS
    This script accepts no inputs.

.OUTPUTS
    This script has no outputs.
#>

#Clear-Host

function Get-UserInfo {
    [cmdletbinding()]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            HelpMessage = 'DisplayName of user')]
        [string]$DisplayName,
        [Parameter(
            Mandatory = $false,
            Position = 1,
            ValueFromPipeline = $false,
            HelpMessage = 'Domain Controller NetBIOS name')]
        [string]$Server = $(Get-ADDomainController -DomainName $($(Get-ADDomain).Forest) -Discover),
        [Parameter(
            Mandatory = $false,
            Position = 2,
            ValueFromPipeline = $false,
            HelpMessage = 'DistinguishedName to search')]
        [string]$SearchBase = $(Get-ADDomain).DistinguishedName
    )

    process {
        [System.Collections.ArrayList]$UserProperties = @{}
        $UserProperties.Add('Company') | Out-Null
        $UserProperties.Add('Created') | Out-Null
        $UserProperties.Add('Description') | Out-Null
        $UserProperties.Add('EmailAddress') | Out-Null
        $UserProperties.Add('Enabled') | Out-Null
        $UserProperties.Add('IPPhone') | Out-Null
        $UserProperties.Add('MemberOf') | Out-Null
        $UserProperties.Add('Name') | Out-Null
        $UserProperties.Add('OfficePhone') | Out-Null
        $UserProperties.Add('PasswordExpired') | Out-Null
        $UserProperties.Add('PasswordLastSet') | Out-Null
        $UserProperties.Add('PwdLastSet') | Out-Null
        $UserProperties.Add('BadPwdCount') | Out-Null
        $UserProperties.Add('LastBadPasswordAttempt') | Out-Null
        $UserProperties.Add('SamAccountName') | Out-Null
        $UserProperties.Add('Title') | Out-Null
        $UserProperties.Add('WhenChanged') | Out-Null
        foreach ($num in 1..15) {
            $UserProperties.Add("extensionAttribute$num") | Out-Null
        }
        
        $SearchFilter = "(Name -like '*$DisplayName*')"

        $UserList = Get-ADUser -SearchBase $SearchBase -Properties $UserProperties -Server $Server -Filter $SearchFilter | Select-Object $UserProperties | Sort-Object Created -Descending

        foreach ($User in $UserList) {

            $UserGroups = Get-ADUser -Identity $User.SamAccountName -Properties * | Select-Object -ExpandProperty memberof | Get-ADGroup | Sort-Object Name | Select-Object -ExpandProperty Name
            $GroupQty = $($UserGroups | Measure-Object).Count

            Write-Output $('- ' * 25)
            Write-Output "Server................: $($Server.ToUpper())"
            Write-Output "Enabled...............: $($User.Enabled)"
            Write-Output "Name..................: $($User.Name)"
            Write-Output "Title.................: $($User.Title)"
            Write-Output "Location..............: $($User.Company)"
            Write-Output "EmailAddress..........: $($User.EmailAddress)"
            Write-Output "PhoneExtension........: $($User.IPPhone)"
            Write-Output "OfficePhone...........: $($User.OfficePhone)"
            Write-Output "SamAccountName........: $($User.SamAccountName)"
            Write-Output "Created...............: $($User.Created)"
            Write-Output "WhenCreated...........: $($User.WhenChanged)"
            Write-Output "PasswordLastSet.......: $($User.PasswordLastSet)"
            Write-Output "PasswordExpired.......: $($User.PasswordExpired)"
            Write-Output "BadPwdCount.......... : $($User.BadPwdCount)"
            Write-Output "LastBadPasswordAttempt: $($User.LastBadPasswordAttempt)"
            Write-Output "PwdLastSet............: $(Get-Date $User.PwdLastSet)"
            Write-Output "Description...........: $($User.Description)"
            Write-Output "Groups................: $GroupQty"
            foreach ($Group in $UserGroups) {
                Write-Output "                        $Group"
            }
            foreach ($num in 1..15) {
                $CurrentAttribute = "extensionAttribute$Num"

                if ($null -eq $User.$CurrentAttribute) {
                    continue
                } else {
                    if ($num -le 9) {
                        Write-Output "$CurrentAttribute...: $($User.$CurrentAttribute)"
                    } else {
                        Write-Output "$CurrentAttribute..: $($User.$CurrentAttribute)"
                    }    
                }
            }
        }
    }
}
