@ECHO OFF
PROMPT $H---
TITLE %%~ni
SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
CLS

REM -------------------------------------------------------------------------------
	REM ORDER OF SECTIONS
		REM :COMMENTS
		REM :CHANGE_LOG
		REM :SCRIPT_START
		REM :ELEVATED_CHECK
		REM :SCRIPT_END
		REM :EOF

REM -------------------------------------------------------------------------------
:COMMENTS
	REM AUTHOR TONY BURROWS - SCRIPTING@TIGERGUPPY.COM
	REM THIS SCRIPT FOR SETTING THE POWER PROFILES TO KEEP THE SYSTEM ON AT ALL TIMES
	
	REM PRE REQS: WINDOWS 7 / SERVER 2008R2 AND NEWER
	
REM -------------------------------------------------------------------------------
:CHANGE_LOG
	REM 10-21-12 - INITIAL SCRIPT
	REM 09-02-16 - UPDATED TO INCLUDE WIN 10 POWER OPTIONS
	REM 10-11-22 - ADDED POWER PROFILE RESET
	REM 10-28-24 - ADDED AND ENABLED SEVERAL HIDDEN POWER SETTINGS

REM -------------------------------------------------------------------------------
:SCRIPT_START
REM Administrative permissions required. Detecting permissions...
SET REQ_ELEVIATION=TRUE

IF %REQ_ELEVIATION%==TRUE (
	CALL :ELEVATED_CHECK
)

CLS
ECHO.
ECHO THIS WILL SET THE POWER PROFILES TO KEEP THE SYSTEM ON AT ALL TIMES
ECHO IF YOU DON'T WANT TO DO THIS, PLEASE EXIT NOW
ECHO OTHERWISE, HIT ENTER TO CONTINUE.
PAUSE > NUL
CLS

REM DEFAULT POWER PROFILES, BOTH AC & DC
SET SET_AC_MIN=POWERCFG -SETACVALUEINDEX SCHEME_MIN
SET SET_AC_MAX=POWERCFG -SETACVALUEINDEX SCHEME_MAX
SET SET_AC_BAL=POWERCFG -SETACVALUEINDEX SCHEME_BALANCED
SET SET_DC_MIN=POWERCFG -SETDCVALUEINDEX SCHEME_MIN
SET SET_DC_MAX=POWERCFG -SETDCVALUEINDEX SCHEME_MAX
SET SET_DC_BAL=POWERCFG -SETDCVALUEINDEX SCHEME_BALANCED

REM GUIDs OF POWER SETTINGS THAT DON'T HAVE SHORTNAMES.
	SET DESKTOP_BACKGROUND_SETTINGS=0d7dbae2-4294-402a-ba8e-26777e8488cd
	SET INTEL_GRAPHICS=44f3beca-a7c0-460e-9df2-bb8b99e0cba6
	SET INTEL_POWER_PLAN=3619c3f2-afb2-4afc-b0e9-e7fef372de36
	SET INTERNET_EXPLORER1=b14a8f96-7b67-4e78-8192-b890b1a62b8a
	SET INTERNET_EXPLORER2=02f815b5-a5cf-4c84-bf20-649d1f75d3d8
	SET JAVASCRIPT_TIMER=4c793e7d-a264-42e1-87d3-7a0d2f523ccd
	SET LOW_BATTERY_NOTIFICATION=bcded951-187b-4d05-bccc-f7e51960c258
	SET MULTIMEDIA_SETTINGS=9596fb26-9850-41fd-ac3e-f7c3c00afd4b
	SET POWER_SAVING_MODE=12bbebe6-58d6-4636-95bb-3217ef867c1a
	SET RESERVE_BATTERY_LEVEL=f3c5027d-cd16-4930-aa6b-90db844a8f00
	SET SLIDE_SHOW=309dce9b-bef4-4119-9921-a851fb12f0f4
	SET SYSTEM_COOLING_POLICY=94d3a615-a899-4ac5-ae2b-e4d8f634367f
	SET UNATTENDED_IDLE_SLEEP_TIMEOUT=7bc4a2f9-d8fc-4469-b07b-33eb785aaca0
	SET LOCK_DISPLAY_OFF_TIMEOUT=8ec4b3a5-6868-48c2-be75-4f3044be88a7
	SET ALLOW_AWAY_MODE=25dfa149-5dd1-4736-b5ab-e8a37b5b8187
	SET PROCESSOR_IDLE_DISABLE=5d76a2ca-e8c0-402f-a133-2158492d58ad
	SET CPU_CORE_PARKING=0cc5b647-c1df-4637-891a-dec35c318583
	SET NETWORK_CONNECTIVITY_STANDBY=f15576e8-98b7-4186-b944-eafa664402d9
	SET BATTERY_SAVER_BRIGHTNESS=13d09884-f74e-474a-a852-b6bde8ad03a8
	SET ADAPTIVE_DISPLAY_TIMEOUT=aea3c9a8-7e30-47c6-bc55-a549a0d22f91
	SET POWER_BUTTON_SLEEP_TIMEOUT=3dff71e7-ea1a-4e0e-bf03-2a9a5b00c7cd
	SET USB_SELECTIVE_SUSPEND=48e6b7a6-50f5-4782-a5d4-53bb8f07e226
	SET USB_SETTINGS=2a737441-1930-4402-8d77-b2bebba308a3
	SET WAKE_TIMERS=bd3b718a-0680-4d9d-8ab2-e1d2b4ac806d
	SET WHEN_PLAYING_VIDEO=34c7b99f-9a6d-4b3c-8dc7-b6693b78cef4
	SET WHEN_SHARING_MEDIA=03680956-93bc-4294-bba6-4e0f09bb717f
	SET WIRELESS_ADAPTER_SETTINGS=19cbb8fa-5279-450e-9fac-8a3d5fedd0c1

ECHO Reset power profiles
	POWERCFG -RESTOREDEFAULTSCHEMES

ECHO Disable Hibernate
	POWERCFG -H OFF

ECHO Set active power profile
	POWERCFG -SETACTIVE SCHEME_BALANCED

ECHO Show Unattended Idle Sleep Timeout
	POWERCFG -attributes SUB_SLEEP %UNATTENDED_IDLE_SLEEP_TIMEOUT% -ATTRIB_HIDE

ECHO Set Unattended Idle Sleep Timeout
	REM Minimum:0 (Disabled)
	REM Maximum:4294967295
	REM Increment:1
	REM Default:120 seconds
	REM Units:Seconds
	%SET_AC_MIN% SUB_SLEEP UNATTENDSLEEP 0
	%SET_AC_MAX% SUB_SLEEP UNATTENDSLEEP 0
	%SET_AC_BAL% SUB_SLEEP UNATTENDSLEEP 0
	%SET_DC_MIN% SUB_SLEEP UNATTENDSLEEP 0
	%SET_DC_MAX% SUB_SLEEP UNATTENDSLEEP 0
	%SET_DC_BAL% SUB_SLEEP UNATTENDSLEEP 0

ECHO Show Console Lock Display Off Timeout
	POWERCFG -attributes SUB_VIDEO %LOCK_DISPLAY_OFF_TIMEOUT% -ATTRIB_HIDE

ECHO Set Console Lock Display Off Timeout
	REM Minimum:10
	REM Maximum:3600
	REM Increment:10
	REM Default:60 seconds
	REM Units:Seconds
	%SET_AC_MIN% SUB_VIDEO LOCKDISPLAY 900
	%SET_AC_MAX% SUB_VIDEO LOCKDISPLAY 900
	%SET_AC_BAL% SUB_VIDEO LOCKDISPLAY 900
	%SET_DC_MIN% SUB_VIDEO LOCKDISPLAY 900
	%SET_DC_MAX% SUB_VIDEO LOCKDISPLAY 900
	%SET_DC_BAL% SUB_VIDEO LOCKDISPLAY 900

ECHO Show Away Mode Policy
	POWERCFG -attributes SUB_SLEEP %ALLOW_AWAY_MODE% -ATTRIB_HIDE

ECHO Set Away Mode Policy
	REM Minimum:0 (Disabled)
	REM Maximum:1 (Enabled)
	REM Increment:1
	REM Default:0 (Disabled)
	REM Units:Binary
	%SET_AC_MIN% SUB_SLEEP AWAYMODE 0
	%SET_AC_MAX% SUB_SLEEP AWAYMODE 0
	%SET_AC_BAL% SUB_SLEEP AWAYMODE 0
	%SET_DC_MIN% SUB_SLEEP AWAYMODE 0
	%SET_DC_MAX% SUB_SLEEP AWAYMODE 0
	%SET_DC_BAL% SUB_SLEEP AWAYMODE 0

ECHO Show Processor Idle Disable
	POWERCFG -attributes SUB_PROCESSOR %PROCESSOR_IDLE_DISABLE% -ATTRIB_HIDE

ECHO Set Processor Idle Disable
	REM Minimum:0 (Enabled)
	REM Maximum:1 (Disabled)
	REM Increment:1
	REM Default:0 (Enabled)
	REM Units:Binary
	%SET_AC_MIN% SUB_PROCESSOR PROCESSORIDLE 0
	%SET_AC_MAX% SUB_PROCESSOR PROCESSORIDLE 0
	%SET_AC_BAL% SUB_PROCESSOR PROCESSORIDLE 0
	%SET_DC_MIN% SUB_PROCESSOR PROCESSORIDLE 0
	%SET_DC_MAX% SUB_PROCESSOR PROCESSORIDLE 0
	%SET_DC_BAL% SUB_PROCESSOR PROCESSORIDLE 0

ECHO Show CPU Core Parking
	POWERCFG -attributes SUB_PROCESSOR %CPU_CORE_PARKING% -ATTRIB_HIDE

ECHO Set CPU Core Parking
	REM Minimum:0 (Unparked)
	REM Maximum:100 (Fully parked)
	REM Increment:1
	REM Default:100
	REM Units:Percentage
	%SET_AC_MIN% SUB_PROCESSOR COREPARKING 100
	%SET_AC_MAX% SUB_PROCESSOR COREPARKING 100
	%SET_AC_BAL% SUB_PROCESSOR COREPARKING 100
	%SET_DC_MIN% SUB_PROCESSOR COREPARKING 100
	%SET_DC_MAX% SUB_PROCESSOR COREPARKING 100
	%SET_DC_BAL% SUB_PROCESSOR COREPARKING 100

ECHO Show Network Connectivity in Standby
	POWERCFG -attributes SUB_SLEEP %NETWORK_CONNECTIVITY_STANDBY% -ATTRIB_HIDE

ECHO Set Network Connectivity in Standby
	REM Minimum:0 (Disable)
	REM Maximum:1 (Enable)
	REM Increment:1
	REM Default:0 (Disable)
	REM Units:Binary
	%SET_AC_MIN% SUB_SLEEP NETWORKCONNECT 1
	%SET_AC_MAX% SUB_SLEEP NETWORKCONNECT 1
	%SET_AC_BAL% SUB_SLEEP NETWORKCONNECT 1
	%SET_DC_MIN% SUB_SLEEP NETWORKCONNECT 1
	%SET_DC_MAX% SUB_SLEEP NETWORKCONNECT 1
	%SET_DC_BAL% SUB_SLEEP NETWORKCONNECT 1

ECHO Show Brightness when battery saver is active
	POWERCFG -attributes SUB_ENERGYSAVER %BATTERY_SAVER_BRIGHTNESS% -ATTRIB_HIDE

ECHO Set Brightness when battery saver is active
	REM Minimum:0
	REM Maximum:100
	REM Increment:1
	REM Default:70
	REM Units:Percentage
	%SET_AC_MIN% SUB_ENERGYSAVER BATTERYBRIGHT 50
	%SET_AC_MAX% SUB_ENERGYSAVER BATTERYBRIGHT 50
	%SET_AC_BAL% SUB_ENERGYSAVER BATTERYBRIGHT 50
	%SET_DC_MIN% SUB_ENERGYSAVER BATTERYBRIGHT 50
	%SET_DC_MAX% SUB_ENERGYSAVER BATTERYBRIGHT 50
	%SET_DC_BAL% SUB_ENERGYSAVER BATTERYBRIGHT 50

ECHO Show Adaptive Display Timeout
	POWERCFG -attributes SUB_VIDEO %ADAPTIVE_DISPLAY_TIMEOUT% -ATTRIB_HIDE

ECHO Set Adaptive Display Timeout
	REM Minimum:10
	REM Maximum:300
	REM Increment:10
	REM Default:300 seconds
	REM Units:Seconds
	%SET_AC_MIN% SUB_VIDEO ADAPTIVEDISPLAY 300
	%SET_AC_MAX% SUB_VIDEO ADAPTIVEDISPLAY 300
	%SET_AC_BAL% SUB_VIDEO ADAPTIVEDISPLAY 300
	%SET_DC_MIN% SUB_VIDEO ADAPTIVEDISPLAY 300
	%SET_DC_MAX% SUB_VIDEO ADAPTIVEDISPLAY 300
	%SET_DC_BAL% SUB_VIDEO ADAPTIVEDISPLAY 300

ECHO Show Sleep timeout for power buttons
	POWERCFG -attributes SUB_SLEEP %POWER_BUTTON_SLEEP_TIMEOUT% -ATTRIB_HIDE

ECHO Set Sleep timeout for power buttons
	REM Minimum:0
	REM Maximum:60
	REM Increment:1
	REM Default:10 seconds
	REM Units:Seconds
	%SET_AC_MIN% SUB_SLEEP BUTTONSLEEP 0
	%SET_AC_MAX% SUB_SLEEP BUTTONSLEEP 0
	%SET_AC_BAL% SUB_SLEEP BUTTONSLEEP 0
	%SET_DC_MIN% SUB_SLEEP BUTTONSLEEP 0
	%SET_DC_MAX% SUB_SLEEP BUTTONSLEEP 0
	%SET_DC_BAL% SUB_SLEEP BUTTONSLEEP 0
	
ECHO Require a password on wakeup
	REM 0:No
	REM 1:Yes
	
	%SET_AC_MIN% SUB_NONE CONSOLELOCK 1
	%SET_AC_MAX% SUB_NONE CONSOLELOCK 1
	%SET_AC_BAL% SUB_NONE CONSOLELOCK 1
	
	%SET_DC_MIN% SUB_NONE CONSOLELOCK 1
	%SET_DC_MAX% SUB_NONE CONSOLELOCK 1
	%SET_DC_BAL% SUB_NONE CONSOLELOCK 1

ECHO Turn off hard disk after
	REM Minimum:0 - Disabled
	REM Maximum:4294967295
	REM Increment:1
	REM Units:Seconds
	
	%SET_AC_MIN% SUB_DISK DISKIDLE 0
	%SET_AC_MAX% SUB_DISK DISKIDLE 0
	%SET_AC_BAL% SUB_DISK DISKIDLE 0
	
	%SET_DC_MIN% SUB_DISK DISKIDLE 0
	%SET_DC_MAX% SUB_DISK DISKIDLE 0
	%SET_DC_BAL% SUB_DISK DISKIDLE 0

ECHO Desktop background settings
ECHO Slide Show
	REM 0:Available
	REM 1:Paused
	
	%SET_AC_MIN% %DESKTOP_BACKGROUND_SETTINGS% %SLIDE_SHOW% 0
	%SET_AC_MAX% %DESKTOP_BACKGROUND_SETTINGS% %SLIDE_SHOW% 0
	%SET_AC_BAL% %DESKTOP_BACKGROUND_SETTINGS% %SLIDE_SHOW% 0
	
	%SET_DC_MIN% %DESKTOP_BACKGROUND_SETTINGS% %SLIDE_SHOW% 1
	%SET_DC_MAX% %DESKTOP_BACKGROUND_SETTINGS% %SLIDE_SHOW% 1
	%SET_DC_BAL% %DESKTOP_BACKGROUND_SETTINGS% %SLIDE_SHOW% 1

ECHO Wireless Adapter Settings
ECHO Power Saving Mode
	REM 0:Maximum Performance
	REM 1:Low Power Saving
	REM 2:Medium Power Saving
	REM 3:Maximum Power Saving
	
	%SET_AC_MIN% %WIRELESS_ADAPTER_SETTINGS% %POWER_SAVING_MODE% 0
	%SET_AC_MAX% %WIRELESS_ADAPTER_SETTINGS% %POWER_SAVING_MODE% 0
	%SET_AC_BAL% %WIRELESS_ADAPTER_SETTINGS% %POWER_SAVING_MODE% 0
	
	%SET_DC_MIN% %WIRELESS_ADAPTER_SETTINGS% %POWER_SAVING_MODE% 0	
	%SET_DC_MAX% %WIRELESS_ADAPTER_SETTINGS% %POWER_SAVING_MODE% 0
	%SET_DC_BAL% %WIRELESS_ADAPTER_SETTINGS% %POWER_SAVING_MODE% 0

ECHO Sleep
ECHO Sleep after
	REM Minimum:0 - Disabled
	REM Maximum:4294967295
	REM Increment:1
	REM Units:Seconds
	
	%SET_AC_MIN% SUB_SLEEP STANDBYIDLE 0
	%SET_AC_MAX% SUB_SLEEP STANDBYIDLE 0
	%SET_AC_BAL% SUB_SLEEP STANDBYIDLE 0
	
	%SET_DC_MIN% SUB_SLEEP STANDBYIDLE 0
	%SET_DC_MAX% SUB_SLEEP STANDBYIDLE 0
	%SET_DC_BAL% SUB_SLEEP STANDBYIDLE 0

ECHO Allow hybrid sleep
	REM 0:Off
	REM 1:On
	
	%SET_AC_MIN% SUB_SLEEP HYBRIDSLEEP 0
	%SET_AC_MAX% SUB_SLEEP HYBRIDSLEEP 0
	%SET_AC_BAL% SUB_SLEEP HYBRIDSLEEP 0
	
	%SET_DC_MIN% SUB_SLEEP HYBRIDSLEEP 0
	%SET_DC_MAX% SUB_SLEEP HYBRIDSLEEP 0
	%SET_DC_BAL% SUB_SLEEP HYBRIDSLEEP 0

ECHO Hibernate after
	REM Minimum:0 - Disabled
	REM Maximum:4294967295
	REM Increment:1
	REM Units:Seconds
	
	%SET_AC_MIN% SUB_SLEEP HIBERNATEIDLE 0
	%SET_AC_MAX% SUB_SLEEP HIBERNATEIDLE 0
	%SET_AC_BAL% SUB_SLEEP HIBERNATEIDLE 0
	
	%SET_DC_MIN% SUB_SLEEP HIBERNATEIDLE 0
	%SET_DC_MAX% SUB_SLEEP HIBERNATEIDLE 0
	%SET_DC_BAL% SUB_SLEEP HIBERNATEIDLE 0

ECHO Allow wake timers
	REM WAKE_TIMERS=RTCWAKE
	REM 0:Disable
	REM 1:Enable
	
	%SET_AC_MIN% SUB_SLEEP %WAKE_TIMERS% 0
	%SET_AC_MAX% SUB_SLEEP %WAKE_TIMERS% 0
	%SET_AC_BAL% SUB_SLEEP %WAKE_TIMERS% 0
	
	%SET_DC_MIN% SUB_SLEEP %WAKE_TIMERS% 0
	%SET_DC_MAX% SUB_SLEEP %WAKE_TIMERS% 0
	%SET_DC_BAL% SUB_SLEEP %WAKE_TIMERS% 0
	
ECHO Allow sleep with remote (network) opens
	REM 0:OFF
	REM 1:ON
	
	%SET_AC_MIN% SUB_SLEEP REMOTEFILESLEEP 1
	%SET_AC_MAX% SUB_SLEEP REMOTEFILESLEEP 1
	%SET_AC_BAL% SUB_SLEEP REMOTEFILESLEEP 1
	
	%SET_DC_MIN% SUB_SLEEP REMOTEFILESLEEP 1
	%SET_DC_MAX% SUB_SLEEP REMOTEFILESLEEP 1
	%SET_DC_BAL% SUB_SLEEP REMOTEFILESLEEP 1

ECHO USB settings
ECHO USB selective suspend setting
	REM 0:Disabled
	REM 1:Enabled
	
	%SET_AC_MIN% %USB_SETTINGS% %USB_SELECTIVE_SUSPEND% 0
	%SET_AC_MAX% %USB_SETTINGS% %USB_SELECTIVE_SUSPEND% 0
	%SET_AC_BAL% %USB_SETTINGS% %USB_SELECTIVE_SUSPEND% 0
	
	%SET_DC_MIN% %USB_SETTINGS% %USB_SELECTIVE_SUSPEND% 0
	%SET_DC_MAX% %USB_SETTINGS% %USB_SELECTIVE_SUSPEND% 0
	%SET_DC_BAL% %USB_SETTINGS% %USB_SELECTIVE_SUSPEND% 0

ECHO Intel Graphics Settings
ECHO Intel Graphics Power Plan
	REM 0:Maximum Battery Life
	REM 1:Balanced
	REM 2:Maximum Performance
	
	%SET_AC_MIN% %INTEL_GRAPHICS% %INTEL_POWER_PLAN% 2
	%SET_AC_MAX% %INTEL_GRAPHICS% %INTEL_POWER_PLAN% 2
	%SET_AC_BAL% %INTEL_GRAPHICS% %INTEL_POWER_PLAN% 2
	
	%SET_DC_MIN% %INTEL_GRAPHICS% %INTEL_POWER_PLAN% 1
	%SET_DC_MAX% %INTEL_GRAPHICS% %INTEL_POWER_PLAN% 1
	%SET_DC_BAL% %INTEL_GRAPHICS% %INTEL_POWER_PLAN% 1

ECHO Power buttons and lid
ECHO Lid close action
	REM 0:Do nothing
	REM 1:Sleep
	REM 2:Hibernate
	REM 3:Shut down
	
	%SET_AC_MIN% SUB_BUTTONS LIDACTION 0
	%SET_AC_MAX% SUB_BUTTONS LIDACTION 0
	%SET_AC_BAL% SUB_BUTTONS LIDACTION 0
	
	%SET_DC_MIN% SUB_BUTTONS LIDACTION 0
	%SET_DC_MAX% SUB_BUTTONS LIDACTION 0
	%SET_DC_BAL% SUB_BUTTONS LIDACTION 0

ECHO Power button action
	REM 0:Do nothing
	REM 1:Sleep
	REM 2:Hibernate
	REM 3:Shut down
	
	%SET_AC_MIN% SUB_BUTTONS PBUTTONACTION 3
	%SET_AC_MAX% SUB_BUTTONS PBUTTONACTION 3
	%SET_AC_BAL% SUB_BUTTONS PBUTTONACTION 3
	
	%SET_DC_MIN% SUB_BUTTONS PBUTTONACTION 3
	%SET_DC_MAX% SUB_BUTTONS PBUTTONACTION 3
	%SET_DC_BAL% SUB_BUTTONS PBUTTONACTION 3

ECHO Sleep button action
	REM 0:Do nothing
	REM 1:Sleep
	REM 2:Hibernate
	REM 3:Shut down
	
	%SET_AC_MIN% SUB_BUTTONS SBUTTONACTION 1
	%SET_AC_MAX% SUB_BUTTONS SBUTTONACTION 1
	%SET_AC_BAL% SUB_BUTTONS SBUTTONACTION 1
	
	%SET_DC_MIN% SUB_BUTTONS SBUTTONACTION 1
	%SET_DC_MAX% SUB_BUTTONS SBUTTONACTION 1
	%SET_DC_BAL% SUB_BUTTONS SBUTTONACTION 1

ECHO Start menu power button
	REM 0:Sleep
	REM 1:Hibernate
	REM 2:Shut down
	
	%SET_AC_MIN% SUB_BUTTONS UIBUTTON_ACTION 0
	%SET_AC_MAX% SUB_BUTTONS UIBUTTON_ACTION 0
	%SET_AC_BAL% SUB_BUTTONS UIBUTTON_ACTION 0
	
	%SET_DC_MIN% SUB_BUTTONS UIBUTTON_ACTION 0
	%SET_DC_MAX% SUB_BUTTONS UIBUTTON_ACTION 0
	%SET_DC_BAL% SUB_BUTTONS UIBUTTON_ACTION 0

ECHO PCI Express
ECHO Link State Power Management
	REM 0:Off
	REM 1:Moderate power savings
	REM 2:Maximum power savings
	
	%SET_AC_MIN% SUB_PCIEXPRESS ASPM 0
	%SET_AC_MAX% SUB_PCIEXPRESS ASPM 0
	%SET_AC_BAL% SUB_PCIEXPRESS ASPM 0
	
	%SET_DC_MIN% SUB_PCIEXPRESS ASPM 1
	%SET_DC_MAX% SUB_PCIEXPRESS ASPM 1
	%SET_DC_BAL% SUB_PCIEXPRESS ASPM 1
	
ECHO Processor power management
ECHO Minimum processor state
	REM Minimum:0
	REM Maximum:100
	REM Increment:1
	REM Units:%
	
	%SET_AC_MIN% SUB_PROCESSOR PROCTHROTTLEMIN 5
	%SET_AC_MAX% SUB_PROCESSOR PROCTHROTTLEMIN 5
	%SET_AC_BAL% SUB_PROCESSOR PROCTHROTTLEMIN 5
	
	%SET_DC_MIN% SUB_PROCESSOR PROCTHROTTLEMIN 5
	%SET_DC_MAX% SUB_PROCESSOR PROCTHROTTLEMIN 5
	%SET_DC_BAL% SUB_PROCESSOR PROCTHROTTLEMIN 5

ECHO System cooling policy
	REM SYSTEM_COOLING_POLICY=SYSCOOLPOL
	REM 0:Passive
	REM 1:Active
	
	%SET_AC_MIN% SUB_PROCESSOR %SYSTEM_COOLING_POLICY% 1
	%SET_AC_MAX% SUB_PROCESSOR %SYSTEM_COOLING_POLICY% 1
	%SET_AC_BAL% SUB_PROCESSOR %SYSTEM_COOLING_POLICY% 1
	
	%SET_DC_MIN% SUB_PROCESSOR %SYSTEM_COOLING_POLICY% 0
	%SET_DC_MAX% SUB_PROCESSOR %SYSTEM_COOLING_POLICY% 0
	%SET_DC_BAL% SUB_PROCESSOR %SYSTEM_COOLING_POLICY% 0

ECHO Maximum processor state
	REM Minimum:0
	REM Maximum:100
	REM Increment:1
	REM Units:%
	
	%SET_AC_MIN% SUB_PROCESSOR PROCTHROTTLEMAX 100
	%SET_AC_MAX% SUB_PROCESSOR PROCTHROTTLEMAX 100
	%SET_AC_BAL% SUB_PROCESSOR PROCTHROTTLEMAX 100
	
	%SET_DC_MIN% SUB_PROCESSOR PROCTHROTTLEMAX 100
	%SET_DC_MAX% SUB_PROCESSOR PROCTHROTTLEMAX 100
	%SET_DC_BAL% SUB_PROCESSOR PROCTHROTTLEMAX 100

ECHO Display
ECHO Dim display after
	REM Minimum:0 - Disabled
	REM Maximum:4294967295
	REM Increment:1
	REM Units:Seconds
	
	%SET_AC_MIN% SUB_VIDEO VIDEODIM 0
	%SET_AC_MAX% SUB_VIDEO VIDEODIM 0
	%SET_AC_BAL% SUB_VIDEO VIDEODIM 0
	
	%SET_DC_MIN% SUB_VIDEO VIDEODIM 0
	%SET_DC_MAX% SUB_VIDEO VIDEODIM 0
	%SET_DC_BAL% SUB_VIDEO VIDEODIM 0

ECHO Turn off display after
	REM Minimum:0 - Disabled
	REM Maximum:4294967295
	REM Increment:1
	REM Units:Seconds
	
	%SET_AC_MIN% SUB_VIDEO VIDEOIDLE 0
	%SET_AC_MAX% SUB_VIDEO VIDEOIDLE 0
	%SET_AC_BAL% SUB_VIDEO VIDEOIDLE 0
	
	%SET_DC_MIN% SUB_VIDEO VIDEOIDLE 0
	%SET_DC_MAX% SUB_VIDEO VIDEOIDLE 0
	%SET_DC_BAL% SUB_VIDEO VIDEOIDLE 0

ECHO Display brightness
	REM Minimum:0
	REM Maximum:100
	REM Increment:1
	REM Units:%
	
	%SET_AC_MIN% SUB_VIDEO VIDEONORMALLEVEL 100
	%SET_AC_MAX% SUB_VIDEO VIDEONORMALLEVEL 100
	%SET_AC_BAL% SUB_VIDEO VIDEONORMALLEVEL 100
	
	%SET_DC_MIN% SUB_VIDEO VIDEONORMALLEVEL 100
	%SET_DC_MAX% SUB_VIDEO VIDEONORMALLEVEL 100
	%SET_DC_BAL% SUB_VIDEO VIDEONORMALLEVEL 100

ECHO Dimmed display brightness
	REM Minimum:0
	REM Maximum:100
	REM Increment:1
	REM Units:%
	
	%SET_AC_MIN% SUB_VIDEO VIDEODIMLEVEL 100
	%SET_AC_MAX% SUB_VIDEO VIDEODIMLEVEL 100
	%SET_AC_BAL% SUB_VIDEO VIDEODIMLEVEL 100
	
	%SET_DC_MIN% SUB_VIDEO VIDEODIMLEVEL 100
	%SET_DC_MAX% SUB_VIDEO VIDEODIMLEVEL 100
	%SET_DC_BAL% SUB_VIDEO VIDEODIMLEVEL 100
	
ECHO Enable adaptive brightness
	REM 0:OFF
	REM 1:ON
	
	%SET_AC_MIN% SUB_VIDEO ADAPTBRIGHT 0
	%SET_AC_MAX% SUB_VIDEO ADAPTBRIGHT 0
	%SET_AC_BAL% SUB_VIDEO ADAPTBRIGHT 0
	
	%SET_DC_MIN% SUB_VIDEO ADAPTBRIGHT 0
	%SET_DC_MAX% SUB_VIDEO ADAPTBRIGHT 0
	%SET_DC_BAL% SUB_VIDEO ADAPTBRIGHT 0

ECHO Multimedia settings
ECHO When sharing media
	REM 0:Allow the computer to sleep
	REM 1:Prevent idling to sleep
	REM 2:Allow the computer to enter Away Mode
	
	%SET_AC_MIN% %MULTIMEDIA_SETTINGS% %WHEN_SHARING_MEDIA% 1
	%SET_AC_MAX% %MULTIMEDIA_SETTINGS% %WHEN_SHARING_MEDIA% 1
	%SET_AC_BAL% %MULTIMEDIA_SETTINGS% %WHEN_SHARING_MEDIA% 1
	
	%SET_DC_MIN% %MULTIMEDIA_SETTINGS% %WHEN_SHARING_MEDIA% 1
	%SET_DC_MAX% %MULTIMEDIA_SETTINGS% %WHEN_SHARING_MEDIA% 1
	%SET_DC_BAL% %MULTIMEDIA_SETTINGS% %WHEN_SHARING_MEDIA% 1

ECHO When playing video
	REM 0:Optimize video quality
	REM 1:Balanced
	REM 2:Optimize power savings
	
	%SET_AC_MIN% %MULTIMEDIA_SETTINGS% %WHEN_PLAYING_VIDEO% 0
	%SET_AC_MAX% %MULTIMEDIA_SETTINGS% %WHEN_PLAYING_VIDEO% 0
	%SET_AC_BAL% %MULTIMEDIA_SETTINGS% %WHEN_PLAYING_VIDEO% 0
	
	%SET_DC_MIN% %MULTIMEDIA_SETTINGS% %WHEN_PLAYING_VIDEO% 0
	%SET_DC_MAX% %MULTIMEDIA_SETTINGS% %WHEN_PLAYING_VIDEO% 0
	%SET_DC_BAL% %MULTIMEDIA_SETTINGS% %WHEN_PLAYING_VIDEO% 0

ECHO Internet Explorer
ECHO JavaScript Timer Frequency
	REM 0:Maximum Power Savings
	REM 1:Maximum Performance
	
	%SET_AC_MIN% %INTERNET_EXPLORER1% %JAVASCRIPT_TIMER% 1
	%SET_AC_MAX% %INTERNET_EXPLORER1% %JAVASCRIPT_TIMER% 1
	%SET_AC_BAL% %INTERNET_EXPLORER1% %JAVASCRIPT_TIMER% 1
	
	%SET_AC_MIN% %INTERNET_EXPLORER2% %JAVASCRIPT_TIMER% 1
	%SET_AC_MAX% %INTERNET_EXPLORER2% %JAVASCRIPT_TIMER% 1
	%SET_AC_BAL% %INTERNET_EXPLORER2% %JAVASCRIPT_TIMER% 1
	
	%SET_DC_MIN% %INTERNET_EXPLORER1% %JAVASCRIPT_TIMER% 0
	%SET_DC_MAX% %INTERNET_EXPLORER1% %JAVASCRIPT_TIMER% 0
	%SET_DC_BAL% %INTERNET_EXPLORER1% %JAVASCRIPT_TIMER% 0
	
	%SET_DC_MIN% %INTERNET_EXPLORER2% %JAVASCRIPT_TIMER% 0
	%SET_DC_MAX% %INTERNET_EXPLORER2% %JAVASCRIPT_TIMER% 0
	%SET_DC_BAL% %INTERNET_EXPLORER2% %JAVASCRIPT_TIMER% 0

ECHO Battery
ECHO Critical battery action
	REM 0:Do nothing
	REM 1:Sleep
	REM 2:Hibernate
	REM 3:Shut down
	
	%SET_AC_MIN% SUB_BATTERY BATACTIONCRIT 0
	%SET_AC_MAX% SUB_BATTERY BATACTIONCRIT 0
	%SET_AC_BAL% SUB_BATTERY BATACTIONCRIT 0
	
	%SET_DC_MIN% SUB_BATTERY BATACTIONCRIT 3
	%SET_DC_MAX% SUB_BATTERY BATACTIONCRIT 3
	%SET_DC_BAL% SUB_BATTERY BATACTIONCRIT 3

ECHO Low battery level
	REM Minimum:0 - Disabled
	REM Maximum:100
	REM Increment:1
	REM Units:%
	
	%SET_AC_MIN% SUB_BATTERY BATLEVELLOW 15
	%SET_AC_MAX% SUB_BATTERY BATLEVELLOW 15
	%SET_AC_BAL% SUB_BATTERY BATLEVELLOW 15
	
	%SET_DC_MIN% SUB_BATTERY BATLEVELLOW 15
	%SET_DC_MAX% SUB_BATTERY BATLEVELLOW 15
	%SET_DC_BAL% SUB_BATTERY BATLEVELLOW 15

ECHO Critical battery level
	REM Minimum:0
	REM Maximum:100
	REM Increment:1
	REM Units:%
	
	%SET_AC_MIN% SUB_BATTERY BATLEVELCRIT 5
	%SET_AC_MAX% SUB_BATTERY BATLEVELCRIT 5
	%SET_AC_BAL% SUB_BATTERY BATLEVELCRIT 5
	
	%SET_DC_MIN% SUB_BATTERY BATLEVELCRIT 5
	%SET_DC_MAX% SUB_BATTERY BATLEVELCRIT 5
	%SET_DC_BAL% SUB_BATTERY BATLEVELCRIT 5

ECHO Low battery notification
	REM BATFLAGSLOW=LOW_BATTERY_NOTIFICATION
	REM 0:Off
	REM 1:On
	
	%SET_AC_MIN% SUB_BATTERY %LOW_BATTERY_NOTIFICATION% 0
	%SET_AC_MAX% SUB_BATTERY %LOW_BATTERY_NOTIFICATION% 0
	%SET_AC_BAL% SUB_BATTERY %LOW_BATTERY_NOTIFICATION% 0
	
	%SET_DC_MIN% SUB_BATTERY %LOW_BATTERY_NOTIFICATION% 1
	%SET_DC_MAX% SUB_BATTERY %LOW_BATTERY_NOTIFICATION% 1
	%SET_DC_BAL% SUB_BATTERY %LOW_BATTERY_NOTIFICATION% 1

ECHO Low battery action
	REM 0:Do nothing
	REM 1:Sleep
	REM 2:Hibernate
	REM 3:Shut down
	
	%SET_AC_MIN% SUB_BATTERY BATACTIONLOW 0
	%SET_AC_MAX% SUB_BATTERY BATACTIONLOW 0
	%SET_AC_BAL% SUB_BATTERY BATACTIONLOW 0
	
	%SET_DC_MIN% SUB_BATTERY BATACTIONLOW 0
	%SET_DC_MAX% SUB_BATTERY BATACTIONLOW 0
	%SET_DC_BAL% SUB_BATTERY BATACTIONLOW 0

ECHO Reserve battery level
	REM Minimum:0
	REM Maximum:100
	REM Increment:1
	REM Units:%
	
	%SET_AC_MIN% SUB_BATTERY %RESERVE_BATTERY_LEVEL% 7
	%SET_AC_MAX% SUB_BATTERY %RESERVE_BATTERY_LEVEL% 7
	%SET_AC_BAL% SUB_BATTERY %RESERVE_BATTERY_LEVEL% 7
	
	%SET_DC_MIN% SUB_BATTERY %RESERVE_BATTERY_LEVEL% 7
	%SET_DC_MAX% SUB_BATTERY %RESERVE_BATTERY_LEVEL% 7
	%SET_DC_BAL% SUB_BATTERY %RESERVE_BATTERY_LEVEL% 7

ECHO Interrupt Steering Settings
ECHO Interrupt Steering Mode
	REM 0:Default
	REM 1:Any processor
	REM 2:Any unparked processor with time delay
	REM 3:Any unparked processor
	REM 4:Lock Interrupt Routing
	REM 5:Processor 0
	REM 6:Processor 1
	
	%SET_AC_MIN% SUB_INTSTEER MODE 0
	%SET_AC_MAX% SUB_INTSTEER MODE 0
	%SET_AC_BAL% SUB_INTSTEER MODE 0
	
	%SET_DC_MIN% SUB_INTSTEER MODE 0
	%SET_DC_MAX% SUB_INTSTEER MODE 0
	%SET_DC_BAL% SUB_INTSTEER MODE 0

ECHO Target Load
	REM Minimum:0
	REM Maximum:2710
	REM Increment:1
	REM Units: Tenths of a percent

	%SET_AC_MIN% SUB_INTSTEER PERPROCLOAD 32
	%SET_AC_MAX% SUB_INTSTEER PERPROCLOAD 32
	%SET_AC_BAL% SUB_INTSTEER PERPROCLOAD 32
	
	%SET_DC_MIN% SUB_INTSTEER PERPROCLOAD 32
	%SET_DC_MAX% SUB_INTSTEER PERPROCLOAD 32
	%SET_DC_BAL% SUB_INTSTEER PERPROCLOAD 32
	
ECHO Unparked time trigger
	REM Minimum:0
	REM Maximum:186a0
	REM Increment:1
	REM Units: Milliseconds

	%SET_AC_MIN% SUB_INTSTEER UNPARKTIME 64
	%SET_AC_MAX% SUB_INTSTEER UNPARKTIME 64
	%SET_AC_BAL% SUB_INTSTEER UNPARKTIME 64
	
	%SET_DC_MIN% SUB_INTSTEER UNPARKTIME 64
	%SET_DC_MAX% SUB_INTSTEER UNPARKTIME 64
	%SET_DC_BAL% SUB_INTSTEER UNPARKTIME 64
	
ECHO Idle Resiliency
ECHO Execution Required power request timeout
	REM Minimum:0
	REM Maximum:ffffffff
	REM Increment:1
	REM Units: Seconds

	%SET_AC_MIN% SUB_IR EXECTIME ffffffff
	%SET_AC_MAX% SUB_IR EXECTIME ffffffff
	%SET_AC_BAL% SUB_IR EXECTIME ffffffff
	
	%SET_DC_MIN% SUB_IR EXECTIME 12c
	%SET_DC_MAX% SUB_IR EXECTIME 12c
	%SET_DC_BAL% SUB_IR EXECTIME 12c

Power Setting GUID: (IO coalescing timeout)
	REM Minimum:0
	REM Maximum:ffffffff
	REM Increment:1
	REM Units: Milliseconds

	%SET_AC_MIN% SUB_IR COALTIME 32
	%SET_AC_MAX% SUB_IR COALTIME 32
	%SET_AC_BAL% SUB_IR COALTIME 32
	
	%SET_DC_MIN% SUB_IR COALTIME 32
	%SET_DC_MAX% SUB_IR COALTIME 32
	%SET_DC_BAL% SUB_IR COALTIME 32

Power Setting GUID: (Processor Idle Resiliency Timer Resolution)
	REM Minimum:0
	REM Maximum:fde8
	REM Increment:1
	REM Units:Milliseconds

	%SET_AC_MIN% SUB_IR PROCIR 7530
	%SET_AC_MAX% SUB_IR PROCIR 7530
	%SET_AC_BAL% SUB_IR PROCIR 7530
	
	%SET_DC_MIN% SUB_IR PROCIR 7530
	%SET_DC_MAX% SUB_IR PROCIR 7530
	%SET_DC_BAL% SUB_IR PROCIR 7530
	
ECHO Presence Aware Power Behavior
ECHO Non-sensor Input Presence Timeout
	REM Minimum:0
	REM Maximum:ffffffff
	REM Increment:1
	REM Units:Seconds

	%SET_AC_MIN% SUB_PRESENCE NSENINPUTPRETIME f0
	%SET_AC_MAX% SUB_PRESENCE NSENINPUTPRETIME f0
	%SET_AC_BAL% SUB_PRESENCE NSENINPUTPRETIME f0
	
	%SET_DC_MIN% SUB_PRESENCE NSENINPUTPRETIME f0
	%SET_DC_MAX% SUB_PRESENCE NSENINPUTPRETIME f0
	%SET_DC_BAL% SUB_PRESENCE NSENINPUTPRETIME f0

GOTO :SCRIPT_END
REM -------------------------------------------------------------------------------
:ELEVATED_CHECK
	NET SESSION >nul 2>&1
	IF %errorLevel% == 0 (
		ECHO ADMINISTRATIVE PERMISSIONS CONFIRMED.
	) ELSE (
		CLS
		ECHO.
		ECHO PLEASE RUN AS ADMINISTRATOR.
		GOTO :SCRIPT_END
	)
	CLS
	ECHO RUNNING AS ADMINISTRATOR.
GOTO :EOF

:SCRIPT_END
ECHO.
ECHO HIT ANY KEY TO EXIT.
PAUSE >NUL
PROMPT
ENDLOCAL
EXIT

REM -------------------------------------------------------------------------------
:EOF
