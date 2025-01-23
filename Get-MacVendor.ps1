function Get-MacVendor {
    <#
    .SYNOPSIS
        Retrieves vendor (manufacturer) information for a MAC address from macvendorlookup.com.
    
    .DESCRIPTION
        This function accepts a MAC address in nearly any format (e.g., with colons, dashes,
        spaces, or no delimiters). It removes all non-hex characters, ensures only valid
        hexadecimal digits are present, and requires at least 6 hex digits to identify the
        Organizationally Unique Identifier (OUI). It then queries the macvendorlookup.com
        API for vendor/manufacturer information associated with that OUI.
    
    .PARAMETER Mac
        The MAC address to be resolved. May be passed in as a string in various formats,
        or via the pipeline.
    
    .EXAMPLE
        PS C:\> Get-MacVendor "00:23:AB:7B:58:99"
        Retrieves vendor information for the provided MAC address.
    
    .EXAMPLE
        PS C:\> "00-23-AB-7B-58-99","0023AB7B5899" | Get-MacVendor
        Retrieves vendor information for multiple MAC addresses passed via pipeline.
    
    #>
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('MACAddress')]
        [string]$Mac
    )
    
    process {
        # Remove all non-hex characters
        $cleanMac = $Mac -replace '[^A-Fa-f0-9]', ''
    
        # Validate only hex characters are present
        if ($cleanMac -notmatch '^[A-Fa-f0-9]+$') {
            throw 'Invalid MAC address. Only hex characters (0-9, A-F) are allowed.'
        }
    
        # Ensure we have at least 6 hex digits (3 bytes) for the OUI portion
        if ($cleanMac.Length -lt 6) {
            throw 'Invalid MAC address. Need at least 6 hex characters for the OUI.'
        }
    
        # Extract the first 6 hex digits for OUI
        $oui = $cleanMac.Substring(0, 6)
    
        # Build the lookup URL
        $url = "https://www.macvendorlookup.com/api/v2/$oui"
    
        try {
            # Perform the REST call
            $result = Invoke-RestMethod -Uri $url -Method Get
            $result
        } catch {
            throw "Failed to retrieve MAC vendor information: $($_.Exception.Message)"
        }
    }
}
