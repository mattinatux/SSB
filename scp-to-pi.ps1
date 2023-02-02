<# SCP step. Moved this out of icalbuddy.ps1 to address issues that stopped the cron.
The If/Else addresses an issue with the client IP changing on the VPN. "It's only temporary unless it works." #>

if (test-connection -computername 192.168.2.2 -count 1 -timetolive 128 -quiet) {
    scp -q /Volumes/drivemecrazy/Tech/Scripts/SimpleScheduleBoard/index.html pi@192.168.2.2:/var/www/html/index.html
} elseif (test-connection -computername 192.168.2.3 -count 1 -timetolive 128 -quiet) {
    scp -q /Volumes/drivemecrazy/Tech/Scripts/SimpleScheduleBoard/index.html pi@192.168.2.3:/var/www/html/index.html
}