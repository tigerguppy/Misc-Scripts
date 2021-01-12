<#
.SYNOPSIS
    Import, export, or delete Wi-Fi profiles from previously connected wireless networks.

.DESCRIPTION
    Import, export, or delete Wi-Fi profiles from previously connected wireless networks.
    Export option creates XML files with the wireless key decrypted so it can be
    imported into another computer.

    The delete option allows all the user editable Wi-Fi profiles to be deleted.

    Not all profiles can be imported, exported, or deleted. If a corporate profile is forced
    on a computer via a Group Policy, it is unlikely that profile will be usable by this script.

    Error checking is in place to keep track of profiles that were not imported, exported,
    or deleted properly.

.INPUTS
    None. You cannot pipe objects into this script.

.OUTPUTS
    No objects are output from this script. This script can create XML files from the NETSH commands.

.NOTES
    NAME: WiFi-Profiles.ps1
    VERSION: 2.2
    AUTHOR: Tony Burrows
    EMAIL: scripts@tigerguppy.com
    LASTEDIT: June 28, 2020

    VERSION HISTORY
    Created on August 30, 2017

    Version 1.0 August 30, 2017
        Initial release

    Version 1.1 April 27, 2018
        Automated export process

    Version 2.0 April 27, 2018
        Added option to choose export folder location
        Added option to choose import folder location
        Added option to get profiles
        Added option to delete all profiles
        Added checking for failed imports, exports, and deletes

    Version 2.1 January 1, 2019
        Changed output of SSID list to Out-GridView.
        Standardized seperator line.
    
    Version 2.2 June 28, 2020
        Update methods to approved verbs.
        Create ZIP archive when exporting SSIDs.
        Rewrite file load and save dialogs.
#>

# Check for admin rights
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
            [Security.Principal.WindowsBuiltInRole] "Administrator")) {
    # Relaunch as an elevated process:
    Start-Process powershell.exe "-File", ('"{0}"' -f $MyInvocation.MyCommand.Path) -Verb RunAs
    exit
}

$Separator = ('-') * 60

function Show-Menu {
    param (
        [string]$Title = 'Import-Export SSIDs'
    )
    Clear-Host
    Write-Host "================ SSID Menu ================"
    
    Write-Host "1: Press '1' to export SSIDs"
    Write-Host "2: Press '2' to import SSIDs"
    Write-Host "3: Press '3' to list all SSIDs"
    Write-Host "4: Press '4' to delete ALL exportable SSIDs"
    Write-Host
    Write-Host "Q: Press 'Q' to quit."
    Write-Host 
}

function Export-SSIDs {
    # Save location dialog box
    $startLocation = Get-Location
    [Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
    [System.Windows.Forms.Application]::EnableVisualStyles()
    $browse = New-Object System.Windows.Forms.FolderBrowserDialog
    $browse.ShowNewFolderButton = $true
    $browse.SelectedPath = $startLocation
    $browse.Description = "Select a directory"

    $loop = $true
    while ($loop) {
        if ($browse.ShowDialog() -eq "OK") {
            $loop = $false
            $savePath = $browse.SelectedPath
            $backupPath = new-item -type directory $(get-date -f yyyy-MM-dd_HHmmss)
            Set-Location $backupPath
        }
        else {
            $res = [System.Windows.Forms.MessageBox]::Show("Retry or exit?",
                "Select a location",
                [System.Windows.Forms.MessageBoxButtons]::RetryCancel)
            if ($res -eq "Cancel") {
                #Ends script
                return
            }
        }
    }
    $browse.SelectedPath
    $browse.Dispose()

    # Create new folder on the desktop and set the location to this folder.
    Set-Location $savePath
    $dateTime = $(get-date -f yyyy-MM-dd_HHmmss)
    $backupPath = new-item -type directory $dateTime
    Set-Location $backupPath

    # Parse the Wi-Fi profile list to exclude broken names
    $wifiProfilesLongList = netsh wlan show profile | select-string -pattern "    All User Profile     : "
    $wifiProfiles = $wifiProfilesLongList -replace "    All User Profile     : ", ""

    # Export Wi-Fi profiles to XML files
    $wifiProfileCounter = 0
    $wifiProfileSuccessCounter = 0
    $wifiProfileTotal = $wifiprofiles.Count

    Clear-Host

    Write-Host 'Exporting' $wifiProfileTotal 'profiles to'
    Write-Host $backupPath
    Write-Host
    Write-Host $Separator


    foreach ($i in $wifiProfiles) {
        $wifiProfileCounter++
        
        Clear-Host

        Write-Host
        Write-host 'Exporting profile:'$i
        Write-Host 'Percent complete:' ($wifiProfileCounter / $wifiProfileTotal).ToString("P")

        $j = netsh wlan export profile name=$i key=clear

        $MyMatches = Select-String -InputObject $j -Pattern "successfully" -CaseSensitive

        # Keep track of success and failure
        if ($MyMatches -like "*$i*") {
            $wifiProfileSuccessCounter++
        }
        else {
            $failedProfiles = $failedProfiles, "`n", $i
        }

        Write-Host
        Write-Host $Separator
    }

    $ZipSource = $backupPath.FullName
    $ZipDestination = Join-Path -Path $savePath -ChildPath "$dateTime.zip"

    $ZipSuccessful = $true

    try {
        Get-ChildItem -Path $ZipSource | Compress-Archive -DestinationPath $ZipDestination
    }
    catch {
        $ZipSuccessful = $false
    }

    Clear-Host

    Write-Host
    Write-Host 'Wi-Fi profile export location:'
    Write-Host $ZipDestination
    Write-Host
    Write-Host 'Export attempts:' $wifiProfileCounter
    Write-Host 'Export success: ' $wifiProfileSuccessCounter
    Write-Host 'Export failure: ' ($wifiProfileTotal - $wifiProfileSuccessCounter)
    Write-Host
    Write-Host 'Failed profiles:'
    Write-Host $failedProfiles
    Write-Host
    Write-Host 'Zip successful:' $ZipSuccessful
    Write-Host
    Write-Host $Separator
    Write-Host
    
    Read-Host -Prompt "Press any key to continue..."

    Set-Location $startLocation

}

function Import-SSIDs {
    # Open location dialog box and set load location
    $startLocation = Get-Location
    [Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
    [System.Windows.Forms.Application]::EnableVisualStyles()
    $browse = New-Object System.Windows.Forms.FolderBrowserDialog
    $browse.ShowNewFolderButton = $false
    $browse.SelectedPath = $startLocation
    $browse.Description = "Select a directory"

    $loop = $true
    while ($loop) {
        if ($browse.ShowDialog() -eq "OK") {
            $loop = $false
            $loadPath = $browse.SelectedPath
            Set-Location $loadPath
        }
        else {
            $res = [System.Windows.Forms.MessageBox]::Show("Retry or exit?",
                "Select a location",
                [System.Windows.Forms.MessageBoxButtons]::RetryCancel)
            if ($res -eq "Cancel") {
                #Ends script
                return
            }
        }
    }
    $browse.SelectedPath
    $browse.Dispose()

    # Load profiles
    $wifiProfileSuccessCounter = 0
    $wifiProfileCounter = 0
    $loadList = Get-ChildItem $loadPath -Filter *.xml
    $wifiProfileTotal = $loadList.Length

    Clear-Host

    Write-Host 'Importing' $wifiProfileTotal 'profiles from'
    Write-Host $loadPath
    Write-Host
    Write-Host $Separator
    
    ForEach ($i in $loadList) {
        $wifiProfileCounter++

        Clear-Host
        
        Write-Host
        Write-Host 'Importing profile:' $i
        Write-Host 'Percent complete:' ($wifiProfileCounter / $wifiProfileTotal).ToString("P")
        
        $j = netsh wlan add profile $i
        
        $MyMatches = Select-String -InputObject $j -Pattern "is added on interface" -CaseSensitive
        
        # Keep track of success and failure
        [xml]$x = Get-Content $i
        $ssidName = $x.WLANProfile.name

        if ($MyMatches -like "*$ssidName*") {
            $wifiProfileSuccessCounter++
        }
        else {
            $failedProfiles = $failedProfiles, "`n", $ssidName
        }

        
        Write-Host
        Write-Host $Separator
        
    }

    $failedProfiles = $failedProfiles | Sort-Object

    $wifiProfilesLongList = netsh wlan show profile | select-string -pattern "    All User Profile     : "
    $wifiProfiles = $wifiProfilesLongList -replace "    All User Profile     : ", ""
    
    Clear-Host

    Write-Host
    Write-Host 'Wi-Fi profile import location:'
    Write-Host $LoadPath
    Write-Host
    Write-Host 'Import attempts:' $wifiProfileCounter
    Write-Host 'Import success: ' $wifiProfileSuccessCounter
    Write-Host 'Import failure: ' ($wifiProfileCounter - $wifiProfileSuccessCounter)
    Write-Host 'Total profiles: ' $wifiProfiles.count
    Write-Host
    Write-Host 'Failed profiles:'
    Write-Host $failedProfiles
    Write-Host
    Write-Host $Separator
    Write-Host

    Read-Host -Prompt "Press any key to continue..."
    
    Set-Location $startLocation
}

function Get-SSIDs {
    # Parse the Wi-Fi profile list to exclude broken names
    $wifiProfilesAll
    $wifiProfilesLongList = netsh wlan show profile | select-string -pattern "    All User Profile     : "
    $wifiProfiles = $wifiProfilesLongList -replace "    All User Profile     : ", "`n"
    $wifiProfiles = $wifiProfiles | Sort-Object

    netsh wlan show profile | Out-GridView
    Write-Host
    Write-Host $Separator
    Write-Host 'Exportable Wi-Fi profiles:' $wifiProfiles.count
    Write-Host $Separator
    Write-Host
    Read-Host -Prompt "Press any key to continue..."
}

function Remove-SSIDs {
    $confirmation = Read-Host "Type 'yes' to delete all SSID profiles, hit enter to quit"
    if ($confirmation -eq 'yes') {
        
        $wifiProfilesLongList = netsh wlan show profile | select-string -pattern "    All User Profile     : "
        $wifiProfiles = $wifiProfilesLongList -replace "    All User Profile     : ", ""
        $wifiProfileTotal = $wifiprofiles.Count
        $wifiProfileSuccessCounter = 0
        $wifiProfileCounter = 0

        Write-Host
        Write-Host 'Deleting' $wifiProfileTotal 'Wi-Fi profiles'
        Write-Host
        Write-Host $Separator

        ForEach ($i in $wifiProfiles) {
            $wifiProfileCounter++

            Clear-Host

            Write-Host
            Write-Host 'Deleting profile:' $i
            Write-Host 'Percent complete:' ($wifiProfileCounter / $wifiProfileTotal).ToString("P")
            
            $j = netsh wlan delete profile name="$i"
            
            $MyMatches = Select-String -InputObject $j -Pattern "is deleted from interface" -CaseSensitive
                    
            # Keep track of success and failure
            if ($MyMatches -like "*$i*") {
                $wifiProfileSuccessCounter++
            }
            else {
                $failedProfiles = $failedProfiles, "`n", $i
            }

            Write-Host
            Write-Host $Separator
        }
        
        $wifiProfilesLongList = netsh wlan show profile | select-string -pattern "    All User Profile     : "
        $wifiProfiles = $wifiProfilesLongList -replace "    All User Profile     : ", ""
        
        Clear-Host

        Write-Host 
        Write-Host 'Delete attempts:' $wifiProfileCounter
        Write-Host 'Delete success: ' $wifiProfileSuccessCounter
        Write-Host 'Delete failure: ' ($wifiProfileCounter - $wifiProfileSuccessCounter)
        Write-Host 'Total profiles: ' $wifiProfiles.count
        Write-Host 
        Write-Host 'Failed profiles:'
        Write-Host $failedProfiles
        Write-Host
        Write-Host $Separator
        Write-Host
        
        Read-Host -Prompt "Press any key to continue..."

    } 
}

# Start script
do {
    Show-Menu
    $selection = Read-Host "Please make a selection"
    switch ($selection) {
        '1' {
            Clear-Host
            Export-SSIDs
        } '2' {
            Clear-Host
            Import-SSIDs
        } '3' {
            Clear-Host
            Get-SSIDs
        } '4' {
            Clear-Host
            Remove-SSIDs
        }
    }
}
until ($selection -eq 'q')