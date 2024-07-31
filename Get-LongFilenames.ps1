# Where to search for long file names.
$SearchPath = 'E:\'

# Max lenght of path. Add items longer than or equal to this number to the output report.
$MaxPathLen = 250

# How many files to check before updating the status. 
# Don't set too low (below 100 or so) or it'll impact performance.
$FileQtyBeforeUpdateStatus = 100

# Where to save the output files.
$LogPath = 'C:\Temp'

# Do not edit below this line #

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

# Get current date & time and setup log file.
$LogTime = $(Get-Date -f yyyyMMdd-HHmmss)
$ScriptLogPath = Join-Path -Path $LogPath -ChildPath "$LogTime-LongFilesTranscript.txt" -ErrorAction Stop

Start-Logging

Write-Output "$(Get-Date -Format O) : Getting files from $SearchPath. This may take a while."

# Get all the files in the search path.
$AllItems = Get-ChildItem -Path "$SearchPath" -Recurse -Force -ErrorAction SilentlyContinue

# Get qty of items to check.
$AllItemsQty = $AllItems.Count

Write-Output "$(Get-Date -Format O) : Found $AllItemsQty items."

# Counters for status updates
$CurrentCheck = 0
$FoundLongPaths = 0

# Where to hold the flagged long paths
[System.Collections.ArrayList]$LongFiles = @{}

# Loop through all the items in the search path to look for long paths.
foreach ($Item in $AllItems) {

    # Check if status should be updated.
    if ($CurrentCheck % $FileQtyBeforeUpdateStatus -eq 0) {
        $PercentComplete = $($CurrentCheck / $AllItemsQty) * 100
        Write-Progress -Activity 'Finding long file paths.' -Status "Test: $CurrentCheck / $AllItemsQty. Found: $FoundLongPaths" -PercentComplete $PercentComplete

    }

    # Get the length of the item
    $ItemLen = $($Item.FullName.Trim()).length

    # If length of the item is longer than the desired length, add it to the output list.
    if ($ItemLen -ge $MaxPathLen) {

        $FoundLongPaths ++
        $LongFiles.Add($Item) | Out-Null

    }

    $CurrentCheck ++

}

# Setup output file.
Write-Output "$(Get-Date -Format O) : Found $FoundLongPaths long path names."
$OutputFilePath = Join-Path -Path $LogPath -ChildPath "$LogTime-LongFiles.txt" -ErrorAction Stop

# Output found long paths to a file.
Write-Output "$(Get-Date -Format O) : Long file paths exported to $OutputFilePath"
$LongFiles | Out-File -FilePath $OutputFilePath -NoClobber

Stop-Logging

Start-Process -FilePath "$env:SystemRoot\Explorer.exe" -ArgumentList $LogPath
