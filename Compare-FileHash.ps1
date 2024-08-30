function Compare-FileHash {
    param (
        # Path of first file
        [Parameter(
            Mandatory = $true,
            Position = 0,
            HelpMessage = 'Path 1'
        )]
        [string] $Path1,
        
        # Path of second file
        [Parameter(
            Mandatory = $true,
            Position = 1,
            HelpMessage = 'Path 2'
        )]
        [string] $Path2,
		
        # Record type
        [Parameter(
            Mandatory = $false,
            Position = 2,
            HelpMessage = 'Algorithm type'
        )]
        [ValidateSet('MACTripleDES', 'MD5', 'RIPEMD160', 'SHA1', 'SHA256', 'SHA384', 'SHA512')]
        [string] $Algorithm = 'SHA256'
    )
    
    $Hash1 = Get-FileHash -Algorithm $Algorithm -Path "$Path1"
    $Hash2 = Get-FileHash -Algorithm $Algorithm -Path "$Path2"

    if ($Hash1.Hash -eq $Hash2.Hash) { 
        return $true 
    } else { 
        return $false 
    }

}