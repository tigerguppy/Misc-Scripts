$Profiles = Get-ChildItem -Path $("$env:USERPROFILE\AppData\Local\Google\Chrome\User Data") | Where-Object { ($_.Name -match 'Profile|Default') -and ($_.Name -notmatch 'system') }

foreach ($Profile in $Profiles) {
    Start-Process 'C:\Program Files\Google\Chrome\Application\chrome.exe' -ArgumentList $("--profile-directory=`"$Profile`"")
}
