function Get-Duration {
    param (
        [Parameter(Mandatory)]
        [string]$Start,

        [Parameter(Mandatory)]
        [string]$End
    )

    # Try to parse input strings into datetime objects
    try {
        $StartDate = [datetime]::Parse($Start)
    } catch {
        Write-Error "Invalid Start date format. Please provide a valid date (e.g., 'MM-DD-YYYY')."
        return
    }

    try {
        $EndDate = [datetime]::Parse($End)
    } catch {
        Write-Error "Invalid End date format. Please provide a valid date (e.g., 'MM-DD-YYYY')."
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

    # Adjust negative values
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
        $previousMonth = $EndDate.AddMonths(-1)
        $days += [datetime]::DaysInMonth($previousMonth.Year, $previousMonth.Month)
        $months -= 1
    }
    if ($months -lt 0) {
        $months += 12
        $years -= 1
    }

    # Output the result as a custom object
    [PSCustomObject]@{
        Years   = $years
        Months  = $months
        Days    = $days
        Hours   = $hours
        Minutes = $minutes
        Seconds = $seconds
    }
}
