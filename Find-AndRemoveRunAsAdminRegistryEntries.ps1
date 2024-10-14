<#
.SYNOPSIS
    Searches the Windows registry for entries with the value "RUNASADMIN" in the HKLM and HKU hives and optionally deletes them.

.DESCRIPTION
    This function scans specific registry paths in HKLM and HKU for entries that have a value of "RUNASADMIN". 
    If the -Delete parameter is provided, it will remove the matching registry entries.

.PARAMETER Delete
    If specified, the function will delete the matching registry entries found.

.EXAMPLE
    Find-AndRemoveRegistryEntries
    This will search the registry and output matching entries without deleting them.

.EXAMPLE
    Find-AndRemoveRegistryEntries -Delete
    This will search the registry and delete any matching entries found.

.NOTES
    Version: 1.2
    Author: Your Name
    Date: October 14, 2024
    This function is designed to be part of a PowerShell module for managing registry entries.
#>

function Find-AndRemoveRunAsAdminRegistryEntries {
    [CmdletBinding()]
    param (
        [switch]$Delete
    )

    # Define the registry paths to search
    $registryPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers",
        "Registry::HKEY_USERS\*\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers"
    )

    # Define the specific registry value to look for
    $dataToFind = "RUNASADMIN"

    # Function to search a specific registry path for matching keys and values
    function Search-Registry {
        param (
            [string]$path,
            [string]$userSID  # Optional parameter to capture the user SID
        )

        try {
            # Get all registry key properties in the path
            $keys = Get-ItemProperty -Path $path -ErrorAction Stop
            foreach ($key in $keys.PSObject.Properties) {
                # Check if the key's value contains "RUNASADMIN"
                if ($key.Value -match $dataToFind) {
                    # Output the key name and value
                    Write-Output "Found matching entry in $path"
                    Write-Output "Key: $($key.Name)"
                    Write-Output "Value: $($key.Value)"
                    Write-Output "--------------------------------------"

                    # If the Delete flag is set, remove the registry key
                    if ($Delete) {
                        try {
                            # Remove the registry entry
                            Remove-ItemProperty -Path $path -Name $key.Name -ErrorAction Stop
                            # Output the deletion result, including the user SID for HKU entries
                            if ($userSID) {
                                Write-Output "Deleted key: $($key.Name) from user SID: $userSID"
                            } else {
                                Write-Output "Deleted key: $($key.Name) from path: $path"
                            }
                        } catch {
                            # Handle errors in deletion
                            Write-Error "Failed to delete key: $($key.Name) in $path. Error: $($_.Exception.Message)"
                        }
                    }
                }
            }
        } catch {
            # Handle errors accessing the registry path
            $errorMessage = "Error accessing " + $path + ": " + $_.Exception.Message
            Write-Error $errorMessage
        }
    }

    # Iterate through each registry path and search for matching entries
    foreach ($path in $registryPaths) {
        # For HKU paths, replace '*' with actual user SIDs
        if ($path -like "Registry::HKEY_USERS:*") {
            $userSIDs = Get-ChildItem -Path "Registry::HKEY_USERS\" | ForEach-Object { $_.PSChildName }
            foreach ($sid in $userSIDs) {
                # Replace wildcard with actual user SID in the path
                $userPath = $path -replace "\*", "\$sid"
                Search-Registry -path $userPath -userSID $sid  # Pass the user SID to the search function
            }
        } else {
            # Search in the HKLM path
            Search-Registry -path $path
        }
    }
}
