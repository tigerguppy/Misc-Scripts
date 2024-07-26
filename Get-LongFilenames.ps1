$Path = 'E:\'
$MaxPathLen = 250

# How many files to check before updating the status. 
# Don't set too low (below 100 or so) or it'll impact performance.
$FileQtyBeforeUpdateStatus = 100 
$LogPath = 'C:\Temp'

# Do not edit below this line #
$LogTime = $(Get-Date -f yyyyMMdd-HHmmss)
$ScriptLogPath = Join-Path -Path $LogPath -ChildPath "$LogTime-LongFilesTranscript.txt" -ErrorAction Stop

function Start-Logging {

    Write-Output "$(Get-Date -Format O) : Start transcript."

    if (Test-Path $LogPath) {
        # Path exists, continuing.
        Start-Transcript -Path $ScriptLogPath -NoClobber -ErrorAction Stop

    } else {
        # Path doesn't exist, try to create it.
        New-Item -Type Directory -Path $LogPath -Force -ErrorAction Stop
        Start-Transcript -Path $ScriptLogPath -NoClobber -ErrorAction Stop

    }
}

function Stop-Logging {

    Write-Output "$(Get-Date -Format O) : Stop transcript."
    Stop-Transcript

}

Start-Logging

Write-Output "$(Get-Date -Format O) : Getting files from $Path. This may take a while."

$AllItems = Get-ChildItem -Path "$Path" -Recurse -Force -ErrorAction SilentlyContinue

$AllItemsQty = $($AllItems | Measure-Object).Count

Write-Output "$(Get-Date -Format O) : Found $AllItemsQty items."

$CurrentCheck = 0
$FoundLongPaths = 0

[System.Collections.ArrayList]$LongFiles = @{}

foreach ($Item in $AllItems) {

    if ($CurrentCheck % $FileQtyBeforeUpdateStatus -eq 0) {
        $PercentComplete = $($CurrentCheck / $AllItemsQty) * 100
        Write-Progress -Activity 'Finding long file paths.' -Status "Test: $CurrentCheck / $AllItemsQty. Found: $FoundLongPaths" -PercentComplete $PercentComplete

    }

    $ItemLen = $($Item.FullName.Trim()).length

    if ($ItemLen -gt $MaxPathLen) {

        $FoundLongPaths ++
        $LongFiles.Add($Item) | Out-Null

    }

    $CurrentCheck ++

}

Write-Output "$(Get-Date -Format O) : Found $FoundLongPaths long path names."

$OutputFilePath = Join-Path -Path $LogPath -ChildPath "$LogTime-LongFiles.txt" -ErrorAction Stop

Write-Output "$(Get-Date -Format O) : Long file paths exported to $OutputFilePath"

$LongFiles | Out-File -FilePath $OutputFilePath -NoClobber

Stop-Logging