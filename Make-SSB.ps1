<#
.Synopsis
   Reads an iCloud calendar and outputs a decent looking status board view.
   Step 1 of status board update. (Step 2 is scp script)
.EXAMPLE
   & ./icalbuddy.ps1
.INPUTS
   No inputs, but change $calendarName and $excludes as appropriate
   todo make calendarName and excludes into params
.OUTPUTS
   index.html, outputs to script root path
.NOTES
   icalbuddy is expected to be installed via Homebrew
   Don't forget to allow unsigned scripts to run this!
#>

# Calendar name for icalbuddy to query
$calendarName = 'iCloud Calendar Name'

# Events to exclude from the view
$excludes = @()
$excludes += 'Exclusion1'
$excludes += 'Exclusion2'
$excludes += 'etc.'


function Get-CountOfEvents {
    <# Counts remaining events for the week, Sunday through Saturday
    Outputs # of events for the current week #>
    [CmdletBinding()]
    param(
    [Parameter (Mandatory = $true)] $revisedEventList
    )

    # Object to hold counts
    $myObj = "" | Select-Object thisWeek,nextWeek

    $today = (Get-Date).Date
    # week start
    $monday = $today.AddDays(1 - $today.DayOfWeek.value__)
    # week end
    $sunday = $monday.AddDays(6)
    # next monday
    $nextMonday = $monday.AddDays(7)
    # next week end
    $nextSunday = $monday.AddDays(13)

    # This week
    $i = 0
    # Next week
    $f = 0

    ForEach ($one in ($revisedEventList.datetime)) {
        $date = [datetime]$one
        if (($date -ge $monday) -and ($date -le $sunday)) {
            $i++
        } elseif (($date -ge $nextMonday) -and ($date -le $nextSunday)) {
            $f++
        }
    }

    $myObj.thisWeek = $i
    $myObj.nextWeek = $f

    $myObj
}

# Grabs the time to place in HTML Title
$updateTimeStamp = get-date -format HH:mm

<# Full path to icalbuddy because otherwise can't run from a shortcut / automator #>
# todo document icalbuddy params
$eventList = /opt/homebrew/bin/icalbuddy -ic $calendarName -f -nc -npn -nrd -nnc 20 -n -iep 'title,datetime,notes' -ps '|,|' -po 'datetime,title,notes' -b ',' -df '%b %e %Y' -eed eventsToday+120

# add column headers to event list and select
$eventList = $eventList | ConvertFrom-Csv -Header e,datetime,title,notes | Select-Object datetime,title,notes

# Prune event list of anything in exclusion list
$revisedEventList = @()
forEach ($eventy in $eventList) {
    if (!($eventy | Select-String -Pattern $excludes)) {
        $revisedEventList += $eventy
    }
    else {
        write-debug "$event matches exclusion filter"
    }
}

# Split datetime into three columns, added for better View
$revisedEventList | ForEach-Object {
    $date = $_.datetime.split(" at ")[0]; 
    $time = $_.datetime.split(" at ")[1]; 
    $year = $date.substring($date.length - 4, 4);

    <# Remove the year from the date column, since it is going into it's own now.
    This regex just replaces the last 5 characters with nothing #>
    $date = $date -replace ".{5}$"

    <# Changes datetime column to a proper date but without time #>
    $_.datetime = ($date.Substring(5)) + " " + $year

    <# Substring 5 to remove blank space before the date. Trim wouldn't work. #>
    $_ | Add-Member -MemberType NoteProperty -Name date -Value ($date.Substring(5)); 
    $_ | Add-Member -MemberType NoteProperty -Name time -Value $time;
    $_ | Add-Member -MemberType NoteProperty -Name year -Value $year;
}

# Add DOW column to schedule
$revisedEventList | ForEach-Object {
    $dow = ((([datetime]$_.datetime).DayOfWeek).ToString().Substring(0,3)); 
    $_ | Add-Member -MemberType NoteProperty -Name dow -Value $dow
}

# Grab the first 12 (b/c screen res) and order the columns
$orderedEventList = $revisedEventList | Select-Object dow,date,time,title,notes -First 12

# Make the Schedule (event list) HTML Fragment to insert into the web View
$orderedEventListHTML = $orderedEventList | ConvertTo-Html -Fragment -Property dow, date, time, title, notes

# Count of Events for this week and next week
$eventCounts = Get-CountOfEvents -revisedEventList $revisedEventList
$numThisWk = $eventCounts.thisWeek
$numNextWk = $eventCounts.nextWeek

<# CSS STARTS HERE
body.day and body.night are for day mode / night mode in JS
grid container is specific to 720x480 display. might change to viewport percentage in future
the rest is pretty self-explanatory #>
$css = '
    body.day {
        background: rgba(0,0,0,0);
    }
    
    body.night {
        background: rgba(0,0,0,1);
    }

    .container {  display: grid;
    grid-template-columns: 180px 540px;
    grid-template-rows: 60px 180px 240px;
    gap: 1px 1px;
    grid-auto-flow: row;
    justify-content: center;
    align-content: stretch;
    justify-items: stretch;
    align-items: stretch;
    grid-template-areas:
        "numthiswk todaydate"
        "numthiswk schedule"
        "numnextwk schedule";
    }

    .schedule { grid-area: schedule; 
        background-color: #F8F8FF;
        padding: 5px;
    }

    table {
        border-spacing: 0px;
        font-weight: bold;
        width: 530px;
    }

    table td {
        padding: 7px;
        border-bottom-style: dotted;
        border-bottom-color: black;
        border-bottom-width: 1px;
    }

    /* tr:nth-child(even) { background-color:#FFEBCD; color: #00008B; }
    tr:nth-child(odd) { background-color:#F0FFF0; color: #2E8B57; } */

    tr:nth-child(odd) { background-color:#E9FFFF; color: black; }
    tr:nth-child(even) { background-color:white; color: black; }

    td:first-child {
        width: 48px;
    }
    td:nth-child(2) {
        width: 54px;
    }
    td:nth-child(3) {
        width: 72px;
    }

    .todaydate { grid-area: todaydate;
        background-color: #FFF;
        font-weight: bold;
        color: black;
        display: flex;
        justify-content: center;
        align-items: center;
        font-size: 1.8em;
        border-bottom: black;
        border-bottom-width: medium;
        border-bottom-style: solid;
    }

    .numthiswk { grid-area: numthiswk; 
        background-color: #FFB831;
        display: flex;
        justify-content: center;
        align-items: center;
        flex-wrap: wrap;
        padding: 16px;
    }

    .numnextwk { grid-area: numnextwk; 
        background-color: #00F3FF;
        display: flex;
        justify-content: center;
        align-items: center;
        flex-wrap: wrap;
        padding: 16px;
    }

    .numwkA {
        font-size: 1.25em;
        text-align: center;
        line-height: 1.2;
        font-weight: bold;
    }

    .numwkB {
        font-size: 7em;
        text-align: center;
    }
    '

# START HTML BUILD
$html = ""
$html += "<!DOCTYPE html><html><head><title>"
$html += "411 Board ($updateTimeStamp)"
$html += "</title>"
$html += "<style>$CSS</style>"

# html method didn't work on Safari / iPad OS
# $html += '<meta http-equiv="Refresh" content="3600">'

<# Sets refresh to every 2 minutes (1000 = 1s)
Replaced setInterval with setTimeout, and added true to reload #>
$html += "<script>setTimeout(function(){window.location.reload(1);}, 120000);</script>"

# Moment, used for date stamp on page
$html += '<script src="https://cdnjs.cloudflare.com/ajax/libs/moment.js/2.29.4/moment.min.js"></script>'

# Refresh the page when it comes back into focus, just to make sure it's fresh
$html += '<script>window.onblur= function() {window.onfocus= function () {location.reload(true)}};</script>'

$html += "</head>"

# START of body section
$html += '<body>'
$html += '<span id="overlay">'
$html += '<div class="container">
    <div class="schedule">'

<# SECTION A: SCHEDULE #>
<# Added the REPLACE  on this fragment to get rid of ANSI color codes. Probs should do it sooner. todo
More here: https://old.reddit.com/r/PowerShell/comments/8z62js/powershell_core_on_linux_remove_color_codes_from/ #>
$html += $orderedEventListHTML -replace '\x1b\[[0-9;]*[a-z]', '' 

<# SECTION B: TODAY'S DATE HEADER #>
$html += '</div>
    <div class="todaydate">'

<# Removed in preference of using javascript and moment.js #>
# $html += "$todayFormatted"

$html += '<span id="date-time"></span>'
$html += '</div>
    <div class="numthiswk">'

<# SECTION C: NUMBER OF APPOINTMENTS THIS WEEK #>
$html += '<span class="numwkA">Appointments This Week</span>'
$html += '<span class="numwkB">'
$html += "$numThisWk</span>"
$html += '</div>
    <div class="numnextwk">'

<# SECTION D: NUMBER OF APPOINTMENTS NEXT WEEK #>
$html += '<span class="numwkA">Appointments <I>Next</I> Week</span>'
$html += '<span class="numwkB">'
$html += "$numNextWk</span>"
$html += '</div>
    </div>'

# Javascript time. Don't forget KISS
$html += '<script>'

# Gets rid of schedule column headers
$html += 'document.getElementsByTagName("tr")[0].remove();'
$html += 'var dtRaw = moment();'

# Formats and inserts date for top of page
$html += "var dt = dtRaw.format('ddd MMMM Do, h:mm a');document.getElementById('date-time').innerHTML=dt;"
$html += 'var hour = dtRaw.hour();'

# Evaluates and executes client side night mode
$html += 'if (hour >= 6 && hour <= 20) {'
$html += 'document.body.className += "day";console.log("Daytime Hours");'
$html += '} else {'
$html += 'document.body.className += "night";document.getElementById("overlay").remove();console.log("Night Hours");}'

$html += '</script>'

$html += "</body></html>"

#output the index.html file to same directory as script
$html | Out-File $PSScriptRoot/index.html