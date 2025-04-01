<##
.SYNOPSIS
    Recursively compares file hashes between two directories.

.DESCRIPTION
    This function scans two directories recursively, calculates the specified hash algorithm for each file,
    and compares the resulting hashes. It identifies files that are unique or differ in content between directories.

.PARAMETER SourceDir
    Specifies the source directory to compare.

.PARAMETER TargetDir
    Specifies the target directory to compare.

.PARAMETER HashAlgorithm
    Specifies the hash algorithm to use for calculating file hashes. Default is SHA256.
    Supported algorithms: SHA1, SHA256, SHA384, SHA512, MD5.

.PARAMETER NoProgress
    Switch to suppress progress display during the operation.

.EXAMPLE
    Compare-DirectoryHashes -SourceDir "C:\Source" -TargetDir "C:\Target"

.EXAMPLE
    Compare-DirectoryHashes -SourceDir "C:\Source" -TargetDir "C:\Target" -HashAlgorithm MD5 -NoProgress

.NOTES
    Author: Tony Burrows
    Date: 2025-04-01
##>

function Compare-DirectoryHashes {
    param (
        [Parameter(Mandatory)]
        [string]$SourceDir,

        [Parameter(Mandatory)]
        [string]$TargetDir,

        [ValidateSet('SHA1', 'SHA256', 'SHA384', 'SHA512', 'MD5')]
        [string]$HashAlgorithm = 'SHA256',

        [switch]$NoProgress
    )

    $totalSteps = 5
    $currentStep = 0

    # Step 1: Scanning Source Directory
    $currentStep++
    if (-not $NoProgress) {
        Write-Progress -Id 0 -Activity 'Comparing Directory Hashes' -Status 'Scanning source directory...' -PercentComplete (($currentStep - 1) / $totalSteps * 100)
    }
    $sourceFilesList = Get-ChildItem -Path $SourceDir -Recurse -File

    # Step 2: Scanning Target Directory
    $currentStep++
    if (-not $NoProgress) {
        Write-Progress -Id 0 -Activity 'Comparing Directory Hashes' -Status 'Scanning target directory...' -PercentComplete (($currentStep - 1) / $totalSteps * 100)
    }
    $targetFilesList = Get-ChildItem -Path $TargetDir -Recurse -File

    # Step 3: Calculating Source Hashes
    $currentStep++
    Write-Output "Calculating hashes for source directory: $SourceDir"
    $sourceFiles = $sourceFilesList | ForEach-Object -Begin { $count = 0; $total = $sourceFilesList.Count } {
        if (-not $NoProgress) {
            $count++
            Write-Progress -ParentId 0 -Id 1 -Activity 'Calculating Source Hashes' -Status $_.FullName -PercentComplete (($count / $total) * 100)
        }
        [PSCustomObject]@{
            RelativePath = $_.FullName.Substring($SourceDir.Length).TrimStart('\')
            Hash         = (Get-FileHash -Path $_.FullName -Algorithm $HashAlgorithm).Hash
        }
    }

    # Step 4: Calculating Target Hashes
    $currentStep++
    Write-Output "Calculating hashes for target directory: $TargetDir"
    $targetFiles = $targetFilesList | ForEach-Object -Begin { $count = 0; $total = $targetFilesList.Count } {
        if (-not $NoProgress) {
            $count++
            Write-Progress -ParentId 0 -Id 2 -Activity 'Calculating Target Hashes' -Status $_.FullName -PercentComplete (($count / $total) * 100)
        }
        [PSCustomObject]@{
            RelativePath = $_.FullName.Substring($TargetDir.Length).TrimStart('\')
            Hash         = (Get-FileHash -Path $_.FullName -Algorithm $HashAlgorithm).Hash
        }
    }

    # Step 5: Comparing Directories
    $currentStep++
    if (-not $NoProgress) {
        Write-Progress -Id 0 -Activity 'Comparing Directory Hashes' -Status 'Comparing directories...' -PercentComplete (($currentStep - 1) / $totalSteps * 100)
        Write-Progress -Id 0 -Activity 'Comparing Directory Hashes' -Completed
    }
    Write-Output 'Comparing directories...'

    $comparison = Compare-Object -ReferenceObject $sourceFiles -DifferenceObject $targetFiles -Property RelativePath, Hash -PassThru

    $comparison | Select-Object RelativePath, Hash, @{Name = 'SideIndicator'; Expression = {
            switch ($_.SideIndicator) {
                '<=' { 'Only in Source or Different' }
                '=>' { 'Only in Target or Different' }
            }
        }
    }
}
