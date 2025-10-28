

param(
    [Parameter(Mandatory = $false)]
    [ValidatePattern('^[A-Za-z0-9._-]{1,20}$')]
    [string]$UserName,

    [Parameter(Mandatory = $false)]
    [string]$FullName,

    [Parameter(Mandatory = $false)]
    [switch]$AddToAdministrators,

    [Parameter(Mandatory = $false)]
    [switch]$PasswordNeverExpires,

    [Parameter(Mandatory = $false)]
    [switch]$AccountNeverExpires,

    [Parameter(Mandatory = $false)]
    [switch]$UserMayNotChangePassword,

    [Parameter(Mandatory = $false)]
    [switch]$BlankPassword,

    [Parameter(Mandatory = $false)]
    [System.Security.SecureString]$Password
)

# ==== ENVIRONMENT DEFAULTS (single place to edit) ====
$Config = @{
    PromptDefaults = @{
        PasswordNeverExpires     = $false   # default for CLI prompt [y/N] -> $false, [Y/n] -> $true
        AccountNeverExpires      = $true
        UserMayChangePassword    = $true
        AddToAdministrators      = $false
    }
    GuiDefaults = @{
        PasswordNeverExpires     = $false
        AccountNeverExpires      = $true
        UserMayChangePassword    = $true
        AddToAdministrators      = $false
    }
    UsernameRegex = '^[A-Za-z0-9._-]{1,20}$'  # change if your env allows other chars/lengths
    Groups = @{
        Users           = 'Users'
        Administrators  = 'Administrators'
    }
}
# ================================================

# Relaunch as admin if not already elevated
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host 'Restarting script as Administrator...'
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = (Get-Process -Id $PID).Path
    $psi.Arguments = ('-NoProfile -ExecutionPolicy Bypass -File "' + $PSCommandPath + '" ' + ($args -join ' '))
    $psi.Verb = 'runas'
    [System.Diagnostics.Process]::Start($psi) | Out-Null
    exit
}

# Minimize PowerShell console window when GUI is shown
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class PSWin {
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
  [DllImport("kernel32.dll", ExactSpelling = true)] public static extern IntPtr GetConsoleWindow();
}
"@
function Hide-ConsoleWindow {
  try {
    $consolePtr = [PSWin]::GetConsoleWindow()
    if ($consolePtr -ne [IntPtr]::Zero) { [PSWin]::ShowWindow($consolePtr, 2) | Out-Null } # 2 = SW_MINIMIZE
  } catch {}
}

# --- Session-only privacy guard (no permanent changes) ---
try { Stop-Transcript -ErrorAction SilentlyContinue | Out-Null } catch {}
$script:__HistBaselineId = (Get-History -ErrorAction SilentlyContinue | Select-Object -Last 1).Id
$script:__PrevMaxHistoryCount = $MaximumHistoryCount
try { $MaximumHistoryCount = 0 } catch { }
try {
    if (Get-Command Set-PSReadLineOption -ErrorAction SilentlyContinue) {
        $script:__TempHistoryPath = Join-Path $env:TEMP ("psrl-" + [guid]::NewGuid().ToString() + ".history")
        Set-PSReadLineOption -HistorySaveStyle SaveNothing -AddToHistoryHandler { return $false } -HistorySavePath $script:__TempHistoryPath -ErrorAction SilentlyContinue | Out-Null
    }
} catch {}

function New-LocalUserSecure {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory = $false)]
        [ValidatePattern('^[A-Za-z0-9._-]{1,20}$')]
        [string]$UserName,

        [Parameter(Mandatory = $false)]
        [string]$FullName,

        [Parameter(Mandatory = $false)]
        [switch]$AddToAdministrators,

        [Parameter(Mandatory = $false)]
        [switch]$PasswordNeverExpires,

        [Parameter(Mandatory = $false)]
        [switch]$AccountNeverExpires,

        [Parameter(Mandatory = $false)]
        [switch]$UserMayNotChangePassword,

        [Parameter(Mandatory = $false)]
        [switch]$BlankPassword,

        [Parameter(Mandatory = $false)]
        [System.Security.SecureString]$Password
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    function Test-IsAdministrator {
        try {
            $id = [Security.Principal.WindowsIdentity]::GetCurrent()
            $p  = New-Object Security.Principal.WindowsPrincipal($id)
            return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        } catch { return $false }
    }

    function Read-VerifiedPassword {
        while ($true) {
            $p1 = Read-Host -Prompt 'Password (leave blank for no password)' -AsSecureString
            $u1 = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($p1)
            $s1 = $null
            try { $s1 = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($u1) } finally { if ($u1 -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($u1) } }
            if ([string]::IsNullOrEmpty($s1)) { return @{ SecurePassword = (New-Object System.Security.SecureString); IsBlank = $true } }
            $p2 = Read-Host -Prompt 'Verify Password' -AsSecureString
            $u2 = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($p2)
            $s2 = $null
            try { $s2 = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($u2) } finally { if ($u2 -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($u2) } }
            if ($s1 -ceq $s2) { return @{ SecurePassword = $p1; IsBlank = $false } }
            Write-Warning 'Passwords do not match. Please try again.'
        }
    }

    function Read-YesNo([string]$Prompt, [bool]$Default = $false) {
        $suffix = if ($Default) { ' [Y/n]' } else { ' [y/N]' }
        while ($true) {
            $ans = Read-Host -Prompt ($Prompt + $suffix)
            if ([string]::IsNullOrWhiteSpace($ans)) { return $Default }
            switch -Regex ($ans.Trim()) {
                '^(y|yes)$' { return $true }
                '^(n|no)$'  { return $false }
                default { Write-Host "Please answer 'y' or 'n'." }
            }
        }
    }

    try {
        if (-not (Test-IsAdministrator)) { throw 'This script must be run in an elevated PowerShell session (as Administrator).' }
        Import-Module -Name Microsoft.PowerShell.LocalAccounts -ErrorAction Stop | Out-Null

        # Interactive prompts only for values not supplied
        if (-not $FullName)  { $FullName  = Read-Host -Prompt 'Full Name (First Last)' }
        if (-not $UserName)  { $UserName  = Read-Host -Prompt 'Username (1-20 letters/numbers/._-)' }
        if (-not $PSBoundParameters.ContainsKey('PasswordNeverExpires')) { if (Read-YesNo 'Password never expires?' $Config.PromptDefaults.PasswordNeverExpires) { $PasswordNeverExpires = $true } }
        if (-not $PSBoundParameters.ContainsKey('AccountNeverExpires')) { if (Read-YesNo 'Account never expires?'  $Config.PromptDefaults.AccountNeverExpires) { $AccountNeverExpires = $true } else { $AccountNeverExpires = $false } }
        if (-not $PSBoundParameters.ContainsKey('UserMayNotChangePassword')) { if (-not (Read-YesNo 'User may change password?' $Config.PromptDefaults.UserMayChangePassword)) { $UserMayNotChangePassword = $true } }
        if (-not $PSBoundParameters.ContainsKey('AddToAdministrators')) { if (Read-YesNo 'Add user to local Administrators?' $Config.PromptDefaults.AddToAdministrators) { $AddToAdministrators = $true } }

        if ($UserName -notmatch $Config.UsernameRegex) { throw 'Username must be 1-20 characters: letters, numbers, dot, underscore, or hyphen.' }

        # Determine password source
        if ($Password) {
            $pwResult = @{ SecurePassword = $Password; IsBlank = $false }
        } elseif ($BlankPassword.IsPresent) {
            Write-Warning 'Creating account with a blank password. This is insecure and not recommended.'
            $pwResult = @{ SecurePassword = (New-Object System.Security.SecureString); IsBlank = $true }
        } else {
            $pwResult = Read-VerifiedPassword
        }
        $securePassword = $pwResult.SecurePassword

        # Safety: block admin+blank
        if ($pwResult.IsBlank -and $AddToAdministrators) {
            throw 'Security check: You cannot create a local Administrator with a blank password. Choose "Add user to local Administrators? = No" or enter a non-empty password, then run again.'
        }

        # Pre-flight
        if (Get-LocalUser -Name $UserName -ErrorAction SilentlyContinue) { throw "A local user named '$UserName' already exists on this system." }

        # Create user
        $params = @{ Name = $UserName; FullName = $FullName; Password = $securePassword }
        if ($PasswordNeverExpires)      { $params['PasswordNeverExpires']      = $true }
        if ($AccountNeverExpires)       { $params['AccountNeverExpires']       = $true }
        if ($UserMayNotChangePassword)  { $params['UserMayNotChangePassword']  = $true }

        Write-Progress -Activity 'Create Local User' -Status 'Creating account' -PercentComplete 25
        if ($PSCmdlet.ShouldProcess("Local user '$UserName'", 'Create')) {
            $newUser = New-LocalUser @params
            Write-Output $newUser
        }

        Write-Progress -Activity 'Create Local User' -Status 'Applying group membership' -PercentComplete 65
        try {
            Add-LocalGroupMember -Group $Config.Groups.Users -Member $UserName -ErrorAction Stop
        } catch { Write-Warning "Failed to add '$UserName' to 'Users': $($_.Exception.Message)" }

        if ($AddToAdministrators) {
            try {
                Add-LocalGroupMember -Group $Config.Groups.Administrators -Member $UserName -ErrorAction Stop
                Write-Output "Added '$UserName' to Administrators."
            } catch { Write-Warning "Failed to add '$UserName' to 'Administrators': $($_.Exception.Message)" }
        }

        Write-Progress -Activity 'Create Local User' -Completed -Status 'Done'
        Write-Output "Local user '$UserName' created successfully."

    } catch {
        Write-Error $_.Exception.Message
        exit 1
    }
}

function Show-CreateLocalUserGUI {
    Add-Type -AssemblyName PresentationFramework, PresentationCore | Out-Null
    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Create Local User" Height="360" Width="520" WindowStartupLocation="CenterScreen">
  <Grid Margin="12">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>
    <Grid.ColumnDefinitions>
      <ColumnDefinition Width="160"/>
      <ColumnDefinition Width="*"/>
    </Grid.ColumnDefinitions>

    <TextBlock Text="Full Name:" Grid.Row="0" Grid.Column="0" VerticalAlignment="Center"/>
    <TextBox x:Name="FullName" Grid.Row="0" Grid.Column="1" Margin="6,4"/>

    <TextBlock Text="Username:" Grid.Row="1" Grid.Column="0" VerticalAlignment="Center"/>
    <TextBox x:Name="UserName" Grid.Row="1" Grid.Column="1" Margin="6,4"/>

    <TextBlock Text="Password:" Grid.Row="2" Grid.Column="0" VerticalAlignment="Center"/>
    <PasswordBox x:Name="Pwd1" Grid.Row="2" Grid.Column="1" Margin="6,4"/>

    <TextBlock Text="Verify Password:" Grid.Row="3" Grid.Column="0" VerticalAlignment="Center"/>
    <PasswordBox x:Name="Pwd2" Grid.Row="3" Grid.Column="1" Margin="6,4"/>

    <StackPanel Orientation="Vertical" Grid.Row="4" Grid.ColumnSpan="2" Margin="0,8,0,0">
      <CheckBox x:Name="ChkAdmins" Content="Add user to local Administrators"/>
      <CheckBox x:Name="ChkPwdNeverExpires" Content="Password never expires"/>
      <CheckBox x:Name="ChkAcctNeverExpires" Content="Account never expires" IsChecked="True"/>
      <CheckBox x:Name="ChkUserMayChange" Content="User may change password" IsChecked="True"/>
    </StackPanel>

    <TextBlock x:Name="ErrorText" Grid.Row="5" Grid.ColumnSpan="2" Foreground="Red" TextWrapping="Wrap"/>

    <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Grid.Row="6" Grid.ColumnSpan="2" Margin="0,8,0,0">
      <Button x:Name="OkBtn" Content="Create" MinWidth="90" Margin="0,0,8,0"/>
      <Button x:Name="CancelBtn" Content="Cancel" MinWidth="90"/>
    </StackPanel>
  </Grid>
</Window>
"@
    $reader = New-Object System.Xml.XmlNodeReader $xaml
    $win = [Windows.Markup.XamlReader]::Load($reader)
    # Minimize console when showing the GUI
    Hide-ConsoleWindow

    $tbFull  = $win.FindName('FullName')
    $tbUser  = $win.FindName('UserName')
    $pb1     = $win.FindName('Pwd1')
    $pb2     = $win.FindName('Pwd2')
    $cbAdm   = $win.FindName('ChkAdmins')
    $cbPwdNE = $win.FindName('ChkPwdNeverExpires')
    $cbAccNE = $win.FindName('ChkAcctNeverExpires')
    $cbUMCP  = $win.FindName('ChkUserMayChange')
    $errTxt  = $win.FindName('ErrorText')
    $ok      = $win.FindName('OkBtn')
    $cancel  = $win.FindName('CancelBtn')

    $script:GuiResult = $null

    # Brushes for validation
        $validBrush   = [Windows.Media.Brushes]::ForestGreen
    $invalidBrush = [Windows.Media.Brushes]::Crimson
    $neutralBrush = [Windows.Media.Brushes]::Black

    # Helpers
    function Get-Plain([System.Security.SecureString]$sec) {
        if (-not $sec) { return $null }
        $b = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
        try { return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($b) } finally { if ($b -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($b) } }
    }
    function Test-UserName([string]$u) { return [bool]($u -match $Config.UsernameRegex) }

    function Update-ValidationState {
        $errTxt.Text = ''
        # Username validation + color
        $u = $tbUser.Text
        if ([string]::IsNullOrWhiteSpace($u)) {
            $tbUser.Foreground = $neutralBrush
        } elseif (Test-UserName $u) {
            $tbUser.Foreground = $validBrush
        } else {
            $tbUser.Foreground = $invalidBrush
        }

        # Password match validation + color (blank allowed)
        $p1 = Get-Plain $pb1.SecurePassword
        $p2 = Get-Plain $pb2.SecurePassword
        if ([string]::IsNullOrEmpty($p1) -and [string]::IsNullOrEmpty($p2)) {
            $pb1.Foreground = $neutralBrush
            $pb2.Foreground = $neutralBrush
            $pwOk = $true
        } elseif ($p1 -ceq $p2) {
            $pb1.Foreground = $validBrush
            $pb2.Foreground = $validBrush
            $pwOk = $true
        } else {
            $pb1.Foreground = $invalidBrush
            $pb2.Foreground = $invalidBrush
            $pwOk = $false
        }

        $userOk = Test-UserName $u
        # Enable Create when username is valid AND (passwords match or both blank) AND not violating blank+admin
        $blank = [string]::IsNullOrEmpty($p1) -and [string]::IsNullOrEmpty($p2)
        $adminChk = [bool]$cbAdm.IsChecked
        $ok.IsEnabled = ($userOk -and $pwOk -and -not ($blank -and $adminChk))
    }

    # Wire up events
    $tbUser.Add_TextChanged({ Update-ValidationState })
    $pb1.Add_PasswordChanged({ Update-ValidationState })
    $pb2.Add_PasswordChanged({ Update-ValidationState })
    $cbAdm.Add_Click({ Update-ValidationState })

    # Apply GUI defaults from Config, then initialize validation
$cbPwdNE.IsChecked = [bool]$Config.GuiDefaults.PasswordNeverExpires
$cbAccNE.IsChecked = [bool]$Config.GuiDefaults.AccountNeverExpires
$cbUMCP.IsChecked  = [bool]$Config.GuiDefaults.UserMayChangePassword
$cbAdm.IsChecked   = [bool]$Config.GuiDefaults.AddToAdministrators

$ok.IsEnabled = $false
Update-ValidationState

    $cancel.Add_Click({ $win.DialogResult = $false })
$ok.Add_Click({
        $errTxt.Text = ''
        $fn = $tbFull.Text
        $un = $tbUser.Text
        if ([string]::IsNullOrWhiteSpace($fn)) { $errTxt.Text = 'Full Name is required.'; return }
        if ([string]::IsNullOrWhiteSpace($un)) { $errTxt.Text = 'Username is required.'; return }
        if ($un -notmatch $Config.UsernameRegex) { $errTxt.Text = 'Username must be 1-20 chars: letters, numbers, dot, underscore, or hyphen.'; return }

        $sp1 = $pb1.SecurePassword
        $sp2 = $pb2.SecurePassword
        $blank = $false
        $b1 = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sp1)
        $b2 = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sp2)
        try {
            $s1 = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($b1)
            $s2 = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($b2)
            if ([string]::IsNullOrEmpty($s1) -and [string]::IsNullOrEmpty($s2)) {
                $blank = $true
            } elseif ($s1 -cne $s2) {
                $errTxt.Text = 'Passwords do not match.'; return
            }
        } finally {
            if ($b1 -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($b1) }
            if ($b2 -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($b2) }
        }

        if ($blank -and $cbAdm.IsChecked) {
            $errTxt.Text = 'Security: cannot add to Administrators with a blank password. Enter a password or uncheck Administrators.'; return
        }

        $script:GuiResult = @{
            UserName                 = $un
            FullName                 = $fn
            AddToAdministrators      = [bool]$cbAdm.IsChecked
            PasswordNeverExpires     = [bool]$cbPwdNE.IsChecked
            AccountNeverExpires      = [bool]$cbAccNE.IsChecked
            UserMayNotChangePassword = -not [bool]$cbUMCP.IsChecked
            Password                 = if ($blank) { New-Object System.Security.SecureString } else { $sp1 }
        }
        $win.DialogResult = $true
    })

    $res = $win.ShowDialog()
    if ($res -eq $true -and $script:GuiResult) { return $script:GuiResult }
    return $null
}

# --- Invoke like a cmdlet, then cleanup history for this session ---
try {
    # Show GUI only when invoked with no switches/args (e.g., right-click Run with PowerShell)
    if (($PSBoundParameters.Count -eq 0) -and ($args.Count -eq 0)) {
        $gui = Show-CreateLocalUserGUI
        if ($gui) { New-LocalUserSecure @gui } else { Write-Verbose 'GUI canceled by user.' }
    } else {
        New-LocalUserSecure @PSBoundParameters
    }
} finally {
    try {
        if ($script:__HistBaselineId) {
            Get-History -ErrorAction SilentlyContinue |
                Where-Object { $_.Id -gt $script:__HistBaselineId } |
                ForEach-Object { Remove-History -Id $_.Id -ErrorAction SilentlyContinue }
        } else {
            Clear-History -ErrorAction SilentlyContinue
        }
    } catch {}
    try { if ($script:__TempHistoryPath -and (Test-Path $script:__TempHistoryPath)) { Remove-Item $script:__TempHistoryPath -Force -ErrorAction SilentlyContinue } } catch {}
    try { if ($null -ne $script:__PrevMaxHistoryCount) { $MaximumHistoryCount = $script:__PrevMaxHistoryCount } } catch {}
}
