<#
.SYNOPSIS
Calculates the elapsed duration between two dates in terms of years, months, days, hours, minutes, and seconds.

.DESCRIPTION
The Get-Duration function calculates the time elapsed between two dates or date-time strings.
It supports various formats and provides a detailed breakdown of the duration.

.PARAMETER Start
The start date or date-time as a string (e.g., 'MM-DD-YYYY', 'YYYY-MM-DD HH:mm:ss AM/PM').

.PARAMETER End
The end date or date-time as a string (e.g., 'MM-DD-YYYY', 'YYYY-MM-DD HH:mm:ss AM/PM').

.OUTPUTS
PSCustomObject
An object containing the elapsed years, months, days, hours, minutes, and seconds.

.EXAMPLES
# Example 1: Just dates
Get-Duration -Start '08-15-2024' -End '11-27-2024'

# Example 2: Date and time (12-hour format)
Get-Duration -Start '08-15-2024 02:30 PM' -End '11-27-2024 08:45 AM'

# Example 3: Date and time (24-hour format)
Get-Duration -Start '2024-08-15 14:30:00' -End '2024-11-27 08:45:00'

.VERSION
1.2.0

.CHANGELOG
Version 1.2.0 - 2024-11-27
- Updated documentation to include examples for 12-hour and 24-hour time formats.
- Improved error handling for invalid date/time input.
- Enhanced user guidance through error messages.

Version 1.1.0 - 2024-11-20
- Added support for date-time formats (12-hour and 24-hour).
- Improved input validation and sanitization.

Version 1.0.0 - 2024-11-15
- Initial version with basic date-only duration calculation.

.NOTES
- Ensure valid date formats to avoid errors.
- The Start date must be earlier than the End date.

.AUTHOR
Tony Burrows
Contact: scripts@tigerguppy.com
#>

function Get-Duration {
    param (
        [Parameter(Mandatory)]
        [string]$Start,  # Start date or date-time as a string (e.g., 'MM-DD-YYYY HH:mm:ss')
        
        [Parameter(Mandatory)]
        [string]$End     # End date or date-time as a string (e.g., 'MM-DD-YYYY HH:mm:ss')
    )

    # Try to parse the input strings into datetime objects
    try {
        $StartDate = [datetime]::Parse($Start)
    } catch {
        Write-Error "Invalid Start date format. Please provide a valid date or date-time (e.g., 'MM-DD-YYYY' or 'MM-DD-YYYY HH:mm:ss AM/PM')."
        return
    }

    try {
        $EndDate = [datetime]::Parse($End)
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
