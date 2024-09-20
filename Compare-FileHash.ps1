<#
.SYNOPSIS
    Compare file hashes between two files or a file and a known hash to ensure they are identical.

.DESCRIPTION
    This script calculates the hash of one or two files and compares them. It supports using a known hash for comparison. The script uses the Get-FileHash cmdlet with an algorithm such as SHA256.

.PARAMETER Path1
    The file path for the first file to be compared.

.PARAMETER Path2
    (Optional) The file path for the second file to be compared. Omit this parameter if using a known hash.

.PARAMETER KnownHash
    (Optional) The known hash to compare the first file against. Use this instead of Path2.

.PARAMETER Algorithm
    (Optional) The hashing algorithm to use (e.g., SHA256, SHA1). Default is SHA256.

.EXAMPLE
    Compare-FileHash.ps1 -Path1 "C:\file1.txt" -Path2 "C:\file2.txt"

.EXAMPLE
    Compare-FileHash.ps1 -Path1 "C:\file1.txt" -KnownHash "D7F37A6BC..."

.NOTES
    Author: Tony Burrows
    Date: 2024-08-30
    Version: 1.1
#>

function Compare-FileHash {
    param (
        # Path of first file
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ParameterSetName = 'CompareTwoFiles',
            HelpMessage = 'Path of file 1'
        )]
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ParameterSetName = 'CompareFileToHash',
            HelpMessage = 'Path of file 1'
        )]
        [string] $SourcePath,
        
        # Path of second file
        [Parameter(
            Mandatory = $true,
            Position = 1,
            ParameterSetName = 'CompareTwoFiles',
            HelpMessage = 'Path of file 2'
        )]
        [string] $ComparePath,

        # Hash to compare
        [Parameter(
            Mandatory = $true,
            Position = 1,
            ParameterSetName = 'CompareFileToHash',
            HelpMessage = 'Hash to compare'
        )]
        [string] $CompareHash,
		
        # Record type
        [Parameter(
            Mandatory = $false,
            Position = 2,
            ParameterSetName = 'CompareTwoFiles',
            HelpMessage = 'Algorithm type'
        )]
        [Parameter(
            Mandatory = $false,
            Position = 2,
            ParameterSetName = 'CompareFileToHash',
            HelpMessage = 'Algorithm type'
        )]
        [ValidateSet('MACTripleDES', 'MD5', 'RIPEMD160', 'SHA1', 'SHA256', 'SHA384', 'SHA512')]
        [string] $Algorithm = 'SHA256'
    )

    switch ($PSCmdlet.ParameterSetName) {
        'CompareTwoFiles' {
            $Hash1 = $(Get-FileHash -Algorithm $Algorithm -Path "$SourcePath").Hash
            $Hash2 = $(Get-FileHash -Algorithm $Algorithm -Path "$ComparePath").Hash
            break
        }

        'CompareFileToHash' {
            $Hash1 = $(Get-FileHash -Algorithm $Algorithm -Path "$SourcePath").Hash
            $Hash2 = $CompareHash
        }
        
    }

    if ($Hash1 -eq $Hash2) { 
        return $true 
    } else { 
        return $false 
    }

}
