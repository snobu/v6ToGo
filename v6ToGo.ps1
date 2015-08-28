#Requires -version 4.0
#Requires -RunAsAdministrator

# ISE doesn't like netsh.exe, we'll fix that:
if ($psUnsupportedConsoleApplications) { $psUnsupportedConsoleApplications.Clear() }

# Here's the interesting bit
$USERID = "userid_from_tunnelbroker.net"
$KEY = "key_from_tunnelbroker.net"
$TUNID = "XXXXXXX"
# Tunnel server's IPv4 endpoint (the other side of the tunnel)
$HEv4endpoint = "4.3.2.1"
# Tunnel server's side of point-to-point /64 allocation
$ipv6HE = "2001:470:XXXX:YYYY::1"
# Your side of point-to-point /64 allocation
$ipv6me = "2001:470:XXXX:YYYY::2"

$URL = "https://ipv4.tunnelbroker.net/ipv4_end.php?ip=AUTO&pass=$KEY&user_id=$USERID&tid=$TUNID"

Write-Output 'Off to tunnelbroker.net to update our local v4 endpoint...'
$response = Invoke-WebRequest -UseBasicParsing $URL | select -Expand Content
if ($response -match "ERROR") {
    throw $response
}

# Get connected interface to v4 Internet
$interface_ip = $(Get-NetIPConfiguration |
                    ? {$_.NetProfile.IPv4Connectivity -eq 'Internet'}).IPV4Address[0].IPAddress

netsh interface teredo set state disabled
netsh interface 6to4 set state disabled

Write-Output 'Removing existing v6 tunnel interface...'
    netsh interface ipv6 delete interface HE-Tunnel

Write-Output "Baking fresh HE-Tunnel interface..."
Write-Host -Foreground Cyan "Our endpoint: $interface_ip `n   Remote HEv4endpoint: $HEv4endpoint"
    netsh interface ipv6 add v6v4tunnel interface=HE-Tunnel $interface_ip $HEv4endpoint
    netsh interface ipv6 add address HE-Tunnel $ipv6me/64
Write-Output "Enabling ipv6 forwarding"
    netsh interface ipv6 set interface HE-Tunnel forwarding=enabled

# Only enable if you want to become a router
# Get network adapter name from ncpa.cpl or Get-NetAdapter
#
# netsh interface ipv6 set interface "Ethernet 2" forwarding=enabled
# Write-Host -ForegroundColor Magenta "You are now an IPv6 router."

Write-Output 'Injecting ::/0 via HE-Tunnel...'
    netsh interface ipv6 add route ::/0 HE-Tunnel $ipv6HE
