<#
.SYNOPSIS
Calculates the elapsed duration between two dates in terms of years, months, days, hours, minutes, and seconds.

.DESCRIPTION
The Get-Duration function calculates the time elapsed between two dates or date-time strings. If one of the parameters (-Start or -End) is omitted, the current date/time is used by default. This simplifies use cases where only one date needs to be specified.

.PARAMETER Start
The start date or date-time as a string (e.g., 'MM-DD-YYYY HH:mm:ss'). Defaults to the current date/time if not provided. Supports 6-digit shorthand format (e.g., '052119' for '05-21-2019').

.PARAMETER End
The end date or date-time as a string (e.g., 'MM-DD-YYYY HH:mm:ss'). Defaults to the current date/time if not provided. Supports 6-digit shorthand format (e.g., '052119' for '05-21-2019').

.OUTPUTS
PSCustomObject
An object containing the elapsed years, months, days, hours, minutes, and seconds between the two dates.

.EXAMPLE
Get-Duration -Start '08-15-2024' -End '11-27-2024'

Calculates the duration between August 15, 2024, and November 27, 2024.

.EXAMPLE
Get-Duration -Start '08-15-2024'

Calculates the duration between August 15, 2024, and the current date/time.

.EXAMPLE
Get-Duration -End '11-27-2024'

Calculates the duration between the current date/time and November 27, 2024.

.EXAMPLE
Get-Duration

Calculates the duration between the current date/time and the current date/time, resulting in zeroed output.

.VERSION
1.5.1

.CHANGELOG
Version 1.5.1 - 2024-12-09
- Added support for parsing 6-digit shorthand dates (MMDDYY) into proper date format.

Version 1.5.0 - 2024-12-09
- Simplified parameter handling using default values for Start and End.
- Removed multiple parameter sets and related complexity.

.AUTHOR
Tony Burrows
Contact: scripts@tigerguppy.com
#>

function Get-Duration {
    param (
        [Parameter(Mandatory = $false)]
        [string]$Start = $(Get-Date), # Start date or date-time as a string (e.g., 'MM-DD-YYYY HH:mm:ss')

        [Parameter(Mandatory = $false)]
        [string]$End = $(Get-Date)  # End date or date-time as a string (e.g., 'MM-DD-YYYY HH:mm:ss')
    )

    # Function to parse dates, including shorthand format (MMDDYY)
    function Parse-Date {
        param (
            [string]$DateString
        )

        if ($DateString -match '^(\d{2})(\d{2})(\d{2})$') {
            # Parse 6-digit shorthand format (MMDDYY)
            $Month = $matches[1]
            $Day = $matches[2]
            $Year = "20$($matches[3])"  # Assume 20xx for 2-digit year
            return [datetime]::ParseExact("$Month-$Day-$Year", 'MM-dd-yyyy', $null)
        } else {
            # Fallback to regular parsing
            return [datetime]::Parse($DateString)
        }
    }

    # Try to parse the input strings into datetime objects
    try {
        $StartDate = Parse-Date -DateString $Start
    } catch {
        Write-Error "Invalid Start date format. Please provide a valid date or date-time (e.g., 'MM-DD-YYYY' or 'MM-DD-YYYY HH:mm:ss AM/PM')."
        return
    }

    try {
        $EndDate = Parse-Date -DateString $End
    } catch {
        Write-Error "Invalid End date format. Please provide a valid date or date-time (e.g., 'MM-DD-YYYY' or 'MM-DD-YYYY HH:mm:ss AM/PM')."
        return
    }

    # Ensure StartDate is earlier than EndDate
    if ($StartDate -gt $EndDate) {
        Write-Error "Start date ($StartDate) must be earlier than End date ($EndDate)."
        return
    }

    # Calculate the duration
    $years = $EndDate.Year - $StartDate.Year
    $months = $EndDate.Month - $StartDate.Month
    $days = $EndDate.Day - $StartDate.Day
    $hours = $EndDate.Hour - $StartDate.Hour
    $minutes = $EndDate.Minute - $StartDate.Minute
    $seconds = $EndDate.Second - $StartDate.Second

    # Adjust negative values for proper calculation
    if ($seconds -lt 0) {
        $seconds += 60
        $minutes -= 1
    }
    if ($minutes -lt 0) {
        $minutes += 60
        $hours -= 1
    }
    if ($hours -lt 0) {
        $hours += 24
        $days -= 1
    }
    if ($days -lt 0) {
        # Get the days of the previous month
        $previousMonth = $EndDate.AddMonths(-1)
        $days += [datetime]::DaysInMonth($previousMonth.Year, $previousMonth.Month)
        $months -= 1
    }
    if ($months -lt 0) {
        $months += 12
        $years -= 1
    }

    # Return the result as a custom object
    [PSCustomObject]@{
        Years   = $years
        Months  = $months
        Days    = $days
        Hours   = $hours
        Minutes = $minutes
        Seconds = $seconds
    }
}
