Clear-Host

$host.privatedata.ErrorBackgroundColor = "white"
#ISE doesn't like netsh.exe, we'll fix that:
if ($psUnsupportedConsoleApplications) { $psUnsupportedConsoleApplications.Clear() }

# Make sure you're running the script with elevated privileges
$USERID = "userid_from_tunnelbroker.net"
$KEY = "key_from_tunnelbroker.net"
$TUNID = "XXXXXXX"

$URL= "https://ipv4.tunnelbroker.net/ipv4_end.php?ip=AUTO&pass=$KEY&user_id=$USERID&tid=$TUNID"

Write-Output 'Off to tunnelbroker.net to update our local v4 endpoint...'
    $ie = New-Object net.webclient
    $ie.DownloadString($URL)

#get connected interface to v4 Internet
$interface_ip = $(gip | ? {$_.NetProfile.IPv4Connectivity -eq 'Internet'}).IPV4Address[0].IPAddress

netsh interface teredo set state disabled
netsh interface 6to4 set state disabled

Write-Output 'Removing old v6 tunnel interface...'
    netsh interface ipv6 delete interface HE-Tunnel

$HEv4endpoint = "216.66.87.14"
#tunnel server's side of point-to-point /64 allocation
$ipv6HE = "2001:470:XXXX:YYYY::1"
#user's side of point-to-point /64 allocation
$ipv6me = "2001:470:XXXX:YYYY::2"

Write-Output "Creating fresh HE-Tunnel interface..."
Write-Host -foreground "yellow" "   Our endpoint: $interface_ip `n   Remote HEv4endpoint: $HEv4endpoint"
    netsh interface ipv6 add v6v4tunnel interface=HE-Tunnel $interface_ip $HEv4endpoint
    netsh interface ipv6 add address HE-Tunnel $ipv6me/64
Write-Output "Enabling ipv6 forwarding"
    netsh interface ipv6 set interface HE-Tunnel forwarding=enabled
    #only enable if you want to become a router
    netsh interface ipv6 set interface Wi-Fi forwarding=enabled

Write-Output 'Injecting ::/0 via HE-Tunnel...'
    netsh interface ipv6 add route ::/0 HE-Tunnel $ipv6HE
