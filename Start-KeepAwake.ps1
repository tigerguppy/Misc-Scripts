<#
.SYNOPSIS
    This script is meant to keep a computer awake without modifying anything on the system.

.DESCRIPTION
	There are situations where keeping a computer awake and unlocked are required however
	it isn't desired to make changes to GPOs (local or domain), power settings, screensaver timer, 
	inactivity timer, etc.. This script is meant to be copied to a system and run without any additional modifications.
	The default key used is Scroll Lock. It is toggled with a 100 ms delay between each of the 2 key presses.

.INPUTS
	None. You cannot pipe objects into this script.

.OUTPUTS
    No objects are output from this script.

.PARAMETER SecondsBetweenKeyPress
	Description: The number of seconds between key presses.
	Required: false
	Type: int32
	
.EXAMPLE
	Start-KeepAwake
		This will use the default timeout of 240 seconds (4 min).

	Start-KeepAwake -SecondsBetweenKeyPress 600
		Press a key every 600 seconds

	Right click on script and choose "Run with PowerShell"
		This will run the script with default settings.

.NOTES
    NAME: Start-KeepAwake.ps1
    VERSION: 1.2
    AUTHOR: Tony Burrows
    EMAIL: scripts@tigerguppy.com
    LASTEDIT: May 4, 2021

    VERSION HISTORY
    Created on April 18, 2020

    Version 1.0 April 18, 2020
		Initial release
		
	Version 1.1 April 24, 2020
		Added fuzzy seconds

	Version 1.1 May 4, 2021
		Added system uptime
#>

function Start-KeepAwake {
	param (
		[Parameter(Mandatory = $false,
			Position = 0, 
			HelpMessage = "Frequency in seconds to toggle the scroll lock to keep system awake.")]
			[ValidateNotNull()]
			[int]$SecondsBetweenKeyPress = 240,
		[Parameter(Mandatory = $false,
			Position = 1, 
			HelpMessage = "Maximum random seconds to add to the keep awake timer.")]
			[ValidateNotNull()]
			[ValidateRange(0, 3600)]
			[int]$MaxFuzzySeconds = 300
	)
		
	# Used to keep track of how long the script is running.
	$LoopCounter = 0
	$SecondsCounter = 0

	# Adjust window title, size, and buffer.
	Set-PSWindowSize -WindowWidth 42 -WindowHeight 14 -WindowTitle "Keep Awake"
	
	# Shell object to send key presses
	$WShell = New-Object -com "Wscript.Shell"

	$MaxPossibleSeconds = $SecondsBetweenKeyPress + $MaxFuzzySeconds
	$MaxPossibleTime = New-TimeSpan -Seconds $MaxPossibleSeconds
	
	#Loop to run everything
	while ($true) {

		if ($MaxFuzzySeconds -eq 0) {
			$FuzzySeconds = 0
		} else {
			$FuzzySeconds = Get-Random -Minimum 0 -Maximum $MaxFuzzySeconds
		}
		
		$TotalLoopSeconds = $SecondsBetweenKeyPress + $FuzzySeconds

		$TimeBetweenKeyPress = New-TimeSpan -Seconds $TotalLoopSeconds
		
		$SystemUptime = (Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime

		# Display info
		Clear-Host
		Write-Host "Base seconds:" $SecondsBetweenKeyPress
		Write-Host "Fuzzy seconds:" $FuzzySeconds
		Write-Host # Space for progress window
		Write-Host # Space for progress window
		Write-Host # Space for progress window
		Write-Host # Space for progress window
		Write-Host # Space for progress window
		Write-Host "Max fuzzy seconds:" $MaxFuzzySeconds
		Write-Host "Toggling Scroll Lock every" $TotalLoopSeconds "seconds."
		Write-Host "Toggling Scroll Lock every:" $TimeBetweenKeyPress.ToString("dd\.hh\:mm\:ss")
		Write-Host "Times Scroll Lock toggled:" $LoopCounter
		Write-Host "System uptime:" $SystemUptime.ToString("dd\.hh\:mm\:ss")
				
		#Status update and delay
		for ($i = $TotalLoopSeconds; $i -ge 1; $i--) {
			# Current runtime timer
			$Runtime = New-TimeSpan -Seconds $SecondsCounter
			$CurrentRuntime = $Runtime.ToString("dd\.hh\:mm\:ss")
	
			# Display status and total runtime
			Write-Progress -Activity "Toggling Scroll Lock" -SecondsRemaining $i -Status "Total runtime: $CurrentRuntime"
			
			# Delay 1 second. This needs to stay at 1 second for all other calculations to stay accurate.
			Start-Sleep -Seconds 1
			
			$SecondsCounter += 1
		}

		# Send key presses
		# See https://ss64.com/vb/sendkeys.html if you want to use a different key.
		$WShell.sendkeys("{SCROLLLOCK}")
		Start-Sleep -Milliseconds 100
		$WShell.sendkeys("{SCROLLLOCK}")
		
		# Keep track of the number of times the computer is kept awake.
		$LoopCounter += 1
	}
}

function Set-PSWindowSize {
	param (
		[Parameter(Mandatory = $true,
			Position = 0, 
			HelpMessage = "Window width.")]
		[ValidateNotNull()]
		[int]$WindowWidth,
		[Parameter(Mandatory = $true,
			Position = 1, 
			HelpMessage = "Window height.")]
		[ValidateNotNull()]
		[int]$WindowHeight,
		[Parameter(Mandatory = $true,
			Position = 2, 
			HelpMessage = "Window title.")]
		[ValidateNotNull()]
		[string]$WindowTitle
	)

	$UI = $Host.UI.RawUI
	$UI.WindowTitle = $WindowTitle
	$UI.WindowSize = New-Object System.Management.Automation.Host.size($WindowWidth, $WindowHeight)
	$BufferSize = $UI.BufferSize
	$WindowSize = $UI.WindowSize
	$BufferSize.Height = $WindowSize.Height
	$BufferSize.Width = $WindowSize.Width
	$UI.BufferSize = $BufferSize
	# Needs to run the window sizing a second time to get rid of the scroll bars.
	$UI.WindowSize = New-Object System.Management.Automation.Host.size($WindowWidth, $WindowHeight)
}

# Run the script.
# This is to allow "Right click and run with PowerShell" and to allow
# running from the shell without importing the script as a module first.
# If the desired mode of operation is to always run from the shell, remove this section.
$SecondsBetweenKeyPress = $args[0]
$MaxFuzzySeconds = $args[1]

if($null -eq $SecondsBetweenKeyPress){
	$SecondsBetweenKeyPress = 240
}

if ($null -eq $MaxFuzzySeconds) {
	$MaxFuzzySeconds = 300
}

Start-KeepAwake -SecondsBetweenKeyPress $SecondsBetweenKeyPress -MaxFuzzySeconds $MaxFuzzySeconds
