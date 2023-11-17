# Check for admin rights before doing anything
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
            [Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    # Relaunch as an elevated process:
    Start-Process powershell.exe '-File', ('"{0}"' -f $MyInvocation.MyCommand.Path) -Verb RunAs
    exit
}

function Install-3rdPartyApps {
    $Apps = @(
        @{Name = '7zip.7zip' },
        @{Name = 'AcroSoftware.CutePDFWriter' },
        @{Name = 'Adobe.Acrobat.Reader.64-bit' },
        @{Name = 'AntibodySoftware.WizTree' },
        @{Name = 'Audacity.Audacity' },
        @{Name = 'Cisco.CiscoWebexMeetings' },
        @{Name = 'Dropbox.Dropbox' },
        @{Name = 'Fortinet.FortiClientVPN' },
        @{Name = 'geeksoftwareGmbH.PDF24Creator' },
        @{Name = 'Google.Chrome' },
        @{Name = 'Google.Drive' },
        @{Name = 'JGraph.Draw' },
        @{Name = 'KeePassXCTeam.KeePassXC' },
        @{Name = 'Logitech.UnifyingSoftware' },
        @{Name = 'Microsoft.AzureCLI' },
        @{Name = 'Microsoft.Office' },
        @{Name = 'Microsoft.PowerToys' },
        @{Name = 'Microsoft.Teams' },
        @{Name = 'Microsoft.VisualStudio.2022.Community' },
        @{Name = 'Microsoft.VisualStudioCode' },
        @{Name = 'Microsoft.WindowsTerminal' },
        @{Name = 'Mozilla.Firefox' },
        @{Name = 'Notepad++.Notepad++' },
        @{Name = 'OpenVPNTechnologies.OpenVPNConnect' },
        @{Name = 'PowerSoftware.AnyBurn' },
        @{Name = 'PrivadoNetworksAG.PrivadoVPN' },
        @{Name = 'PuTTY.PuTTY' },
        @{Name = 'Python.Python.3.12' },
        @{Name = 'Robware.RVTools' },
        @{Name = 'Splashtop.SplashtopBusiness' },
        @{Name = 'Splashtop.SplashtopStreamer.Deployment' },
        @{Name = 'Toggl.ToggleTrack' },
        @{Name = 'VMware.WorkstationPro' },
        @{Name = 'Valve.Steam' },
        @{Name = 'VideoLAN.VLC' },
        @{Name = 'WatchGuardTechnologies.WatchGuardSystemManager' },
        @{Name = 'WinMerge.WinMerge' },
        @{Name = 'WinSCP.WinSCP' },
        @{Name = 'WiresharkFoundation.Wireshark' },
        @{Name = 'Zoom.Zoom' },
        @{Name = 'IDRIX.VeraCrypt' },
        @{Name = 'geeksoftwareGmbH.PDF24Creator' },
        @{Name = 'AntibodySoftware.WizTree' },
        @{Name = 'mRemoteNG.mRemoteNG' },
        @{Name = 'voidtools.Everything'}
    )

    Foreach ($App in $Apps) {
        #check if the app is already installed
        $ListApp = winget list --exact -q $App.Name --accept-source-agreements
        
        # Install app if it ins't installed, upgrade it if it is installed.
        if (![String]::Join('', $ListApp).Contains($App.Name)) {
            Write-Output "Processing $($App.Name)"
            if ($null -ne $App.Source) {
                winget install --exact --silent $App.Name --source $App.Source --accept-source-agreements --accept-package-agreements
            } else {
                winget install --exact --silent $App.Name --accept-source-agreements --accept-package-agreements
            }
        } else {
            winget upgrade --exact --silent $App.Name --accept-source-agreements --accept-package-agreements
        }
    }
}
