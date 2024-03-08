# Meraki Client VPN config
# https://documentation.meraki.com/MX/Client_VPN/Client_VPN_OS_Configuration

$ConnectionName = "VPN Name"
$ServerAddress = "IP or FQDN"
$PresharedKey = "PSK of VPN"

# This is not possible by most OS UI's without a lot of OS specific configs.
$EnableSplitTunnel = $true

# If split tunnel is enabled, what destination routes should be added to this connection? Use CIDR notation.
# i.e. $Destinations = "192.168.100.0/24", "10.100.10.0/24"
$Destinations = "Network 1 CIDR", "Network 2 CIDR"

$WarningPreference = "SilentlyContinue"

Add-VpnConnection -Name "$ConnectionName" -ServerAddress "$ServerAddress" -TunnelType L2tp -L2tpPsk "$PresharedKey" -AuthenticationMethod Pap -Force

if ($EnableSplitTunnel) {
    Set-VpnConnection -Name "$ConnectionName" -SplitTunneling $true -RememberCredential $true -Force
    
    foreach ($Destination in $Destinations) {
        Add-Vpnconnectionroute -Connectionname $ConnectionName -DestinationPrefix $Destination
    }
}
else {
    Set-VpnConnection -Name "$ConnectionName" -RememberCredential $true -Force
}
