<#
https://answers.microsoft.com/en-us/windows/forum/all/windows-temporary-user-profile-temp-issue/5fbefc7c-0b82-4395-bfda-6d7e2ebeacc6

To-Do : Add logic to the removing of the registry keys to prevent the need to start a new user profile. 
#>

$ContinueLoopMain = $true
$LoopCounterMain = 0
$LoopLimit = 10

do {
    $ContinueLoopRegedit = $true
    $LoopCounterRegEdit = 0

    do {
        $ItemsToDeleteRegQty = $(Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\' | Where-Object Name -Like '*.bak' | Measure-Object).Count
        Write-Output "Removing $ItemsToDeleteRegQty registry keys."
        Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\' | Where-Object Name -Like '*.bak' | Remove-Item -Recurse -Force

        if ($ItemsToDeleteRegQty -eq 0) {
            $ContinueLoopRegedit = $false
        } else {
            $ContinueLoopRegedit = $true
        }

        $LoopCounterRegEdit ++
        if ($LoopCounterRegEdit -ge $LoopLimit ) {
            $ContinueLoopRegedit = $false
        }
    } while ( $ContinueLoopRegedit )
    
    # Delete temp user folders
    $ContinueLoopFiles = $true
    $LoopCounterFiles = 0

    do {
        $ItemsToDeleteFiles = $(Get-ChildItem -Path "$env:SystemDrive\Users\" | Where-Object FullName -Like "$env:SystemDrive\Users\Temp*").FullName
        $ItemsToDeleteFilesQty = $($ItemsToDeleteFiles | Measure-Object).Count
        Write-Output "Removing $ItemsToDeleteFilesQty temp profile folders."
        Get-ChildItem -Path "$env:SystemDrive\Users\" | Where-Object Name -Like 'Temp*' | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        
        if ($ItemsToDeleteFilesQty -eq 0) {
            $ContinueLoopFiles = $false
        } else {
            $ContinueLoopFiles = $true
        }

        $LoopCounterFiles ++
        if ($LoopCounterFiles -ge $LoopLimit ) {
            $ContinueLoopFiles = $false
        }

    } while ( $ContinueLoopFiles )
    
    if ($ContinueLoopFiles -or $ContinueLoopRegedit) {
        $ContinueLoopMain = $true
    } else {
        $ContinueLoopMain = $false
    }

    $LoopCounterMain ++
    if ($LoopCounterMain -ge $LoopLimit ) {
        $ContinueLoopMain = $false
    }

} while ( $ContinueLoopMain )
