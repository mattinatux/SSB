UpdateSimpleScheduleBoard.sh invokes icalbuddy.ps1 to generate the HTML, then
invokes scp script to transfer view to remote client.

More info here: <link>

If not using an alternative scheduler (like HomeAssistant in my case), can use cron to run every 15 minutes, e.g.:

> crontab -e
> */15 * * * * open -g /path/To/UpdateSSB.app