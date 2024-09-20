#requires -version 5

Import-Module ActiveDirectory

<#
.SYNOPSIS
    Retrieve detailed user information from Active Directory, including attributes like account status, group membership, and password properties.

.DESCRIPTION
    This script retrieves Active Directory user information based on the provided DisplayName. It can search across multiple domain controllers, return custom attributes, and display user groups and password-related data such as password expiration and lockout status.

.PARAMETER DisplayName
    The display name of the user(s) to query.

.PARAMETER Servers
    (Optional) Domain Controller NetBIOS name(s). Default is the discovered domain controller.

.PARAMETER SearchBase
    (Optional) DistinguishedName for narrowing the search. Defaults to the domain DistinguishedName.

.EXAMPLE
    Get-UserInfo mike
    Retrieves all user information for users with "mike" in their display name.

.EXAMPLE
    Get-UserInfo -DisplayName mike -Servers all
    Queries all domain controllers for users with "mike" in their display name.

.NOTES
    Author: Tony Burrows
    Version: 2.0.4 (Updated 2024-09-20)
    Added account lockout attributes and enhancements to output user properties.
#>

# Script logic starts here


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
        $Servers = $(Get-ADDomainController -Discover).Name,
        [Parameter(
            Mandatory = $false,
            Position = 2,
            ValueFromPipeline = $false,
            HelpMessage = 'DistinguishedName to search')]
        [string]$SearchBase = $(Get-ADDomain).DistinguishedName
    )

    process {

        $Servers = $Servers | Sort-Object

        if ($Servers.ToLower() -eq 'all') {
            $Servers = $(Get-ADDomainController -Filter * | Sort-Object Name).Name
        }

        foreach ($Server in $Servers) {

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
            $UserProperties.Add('LockedOut') | Out-Null
            $UserProperties.Add('AccountLockoutTime') | Out-Null
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
                Write-Output "AccountLockoutTime....: $($User.AccountLockoutTime)"
                Write-Output "LockedOut.............: $($User.LockedOut)"
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
}
