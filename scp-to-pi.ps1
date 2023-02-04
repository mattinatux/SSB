<# SCP step. Moved this out of icalbuddy.ps1 to address issues that stopped the cron.
The If/Else addresses an issue with the client IP changing on the VPN. "It's only temporary unless it works." #>

if (test-connection -computername <IP_OR_NAME_1> -count 1 -timetolive 128 -quiet) {
    scp -q /path/To/index.html pi@<IP_OR_NAME_1>:/var/www/html/index.html
} elseif (test-connection -computername <IP_OR_NAME_2> -count 1 -timetolive 128 -quiet) {
    scp -q /path/To/index.html pi@<IP_OR_NAME_2>:/var/www/html/index.html
}