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
