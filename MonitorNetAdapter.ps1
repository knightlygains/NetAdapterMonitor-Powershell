# Disconnected=0,
# Connecting=1,
# Connected=2,
# Disconnecting=3,
# Hardware_Not_present=4,
# Hardware_disabled=5,
# Hardware_malfunction=6,
# Media_disconnected=7,
# Authenticating=8,
# Authentication_succeeded=9,
# Authentication_failed=10,
# Invalid_address=11,
# Credentials_required=12
Write-Host " _____     _   _____   _         _              _____         _ _           
|   | |___| |_|  _  |_| |___ ___| |_ ___ ___   |     |___ ___|_| |_ ___ ___ 
| | | | -_|  _|     | . | .'| . |  _| -_|  _|  | | | | . |   | |  _| . |  _|
|_|___|___|_| |__|__|___|__,|  _|_| |___|_|    |_|_|_|___|_|_|_|_| |___|_|  
                            |_|                                             
                            "
Write-Host "This script is used to monitor a wireless adapter's connection every second, and then log the date and time the second it is found to be disconnected."
Write-Host ""

$script:time = Get-Date -Format HH:mm:ss

Function getAdapters {
    #Variable that allows us to loop through and get all adapters with 'Wi' in the name.
    $adapters = Get-CimInstance -Class Win32_NetworkAdapter | Select-Object Name, deviceID, NetConnectionStatus

    #Loop through adapters and create/update variables for each one.
    foreach ($adapter in $adapters) {
        Set-Variable -Name "$($adapter.deviceID) : Adapter:$($adapter.Name)" -Value $adapter.NetConnectionStatus -Scope script #create variable
    }
}

#Function to calculate time left from total seconds provided
Function getTimeLeft ($n) {
    $day = ($n / (24 * 3600))
    
    $n = $n % (24 * 3600)
    $hour = $n / 3600

    $n %= 3600
    $minutes = $n / 60

    $n %= 60
    $seconds = $n

    $daysLeft = [Math]::Floor($day)
    $hoursleft = [Math]::Floor($hour)
    $minutesLeft = [Math]::Floor($minutes)

    if ($daysLeft -ge 1) {
        return "Remaining: Day:$daysLeft Hr:$hoursLeft Min:$minutesLeft Sec:$seconds."
    }
    if ($hoursLeft -ge 1) {
        return "Remaining: Hr:$hoursLeft Min:$minutesLeft Sec:$seconds."
    }
    if ($minutesLeft -ge 1) {
        return "Remaining: Min:$minutesLeft Sec:$seconds."
    }
    
    return "Remaining: Sec:$seconds."
}

$script:monitorCount = 1 #Variable to track step in animation
$script:incline = $true #Variable to track direction animation should go in
#Function to update animation
Function monitorAnimation {

    if ($monitorCount -eq 1) {
        Write-Host "|" -ForegroundColor Yellow -NoNewline;
        Write-Host "-   |" -NoNewline
        $script:incline = $true
        if ($incline) {
            $script:monitorCount += 1
        }
        else {
            $script:monitorCount -= 1
        }
        return
    }
    if ($monitorCount -eq 2) {
        Write-Host "| -  |" -NoNewline
        if ($incline) {
            $script:monitorCount += 1
        }
        else {
            $script:monitorCount -= 1
        }
        return
    }
    if ($monitorCount -eq 3) {
        Write-Host "|  - |" -NoNewline
        if ($incline) {
            $script:monitorCount += 1
        }
        else {
            $script:monitorCount -= 1
        }
        return
    }
    if ($monitorCount -eq 4) {
        Write-Host "|   -" -NoNewline
        Write-Host "|" -ForegroundColor Green -NoNewline
        $script:incline = $false
        $script:monitorCount -= 1
        return
    }
}

#Get wifi adapters and create/update variables made from them.
getAdapters

#Variable that will allow us to loop through the variables we made in the function getAdapters
$adapterVariables = Get-Variable -Name "*Adapter*"

#List available network adapter variables for selection
foreach ($adap in $adapterVariables) {
    if ($($adap.value) -eq 2) {
        Write-Host "$($adap.Name) is connected!" -ForegroundColor Green
    }
    else {
        Write-Host "$($adap.Name) is disconnected..." -ForegroundColor Red
    }
}

Write-Host ""

#Get user input for monitoring
$answer = Read-Host "Select an adapter to monitor. (Enter the number seen before 'Adapter')"
Write-Host ""
$answer2 = Read-Host "How long will we monitor? (Answer in minutes)"
Write-Host ""

try {
    $script:monitorLength = [int]$answer2 * 60
}
catch {
    Write-Host "Invalid input for time to wait."
    Write-Host ""
    break
}

#Check input and begin monitoring if necessary
if (-not(Get-Variable -Name "$answer :*")) {
    Write-Host "Invalid adpater selection."
    Write-Host ""
    break
}
else {
    $adapter = Get-Variable -Name "$answer :*" #Get variable that corresponds with our answer
    if (-not($adapter.Value -eq 2)) {
        Write-Host "Device is disconnected. No monitoring necessary."
        Write-Host ""
        break
    }
    else {
        Write-Host "Monitoring $($adapter.Name)."
        Write-Host "Monitoring will begin in 5 seconds and check every second for connection status."
        Write-Host ""
        Start-Sleep 5
    }
}

$script:reconnectTime = $null
$script:disconnectTime = $null
#Function to update results txt file with disconnect info.
Function logConnection ($connectionStart) {
    
    if (-not($null -eq (Get-Variable -Name "$answer :*"))) {
        #Get current user's documents folder
        $userDocuments = [Environment]::GetFolderPath("MyDocuments")
        # Write-Host "$userDocuments"
        $script:resultsDir = "$userDocuments\AdapterMonitorResults"
        $script:resultsTxtPath = "$resultsDir\AdapterMonitorResults.txt"
    
        #If directory already exists
        if (Test-Path $resultsDir) {
            if (-not(Test-Path $resultsTxtPath -PathType leaf)) {
                New-item -Path $resultsDir -Name "AdapterMonitorResults.txt" -ItemType "file" | Out-Null
            }
        }
        else {
            #Make the directory and the txt file
            mkdir $resultsDir | Out-Null
            New-item -Path $resultsDir -Name "AdapterMonitorResults.txt" -ItemType "file" | Out-Null
        }
    
        $adapter = Get-Variable -Name "$answer :*"

        if ($connectionStart) {
            Add-Content -Path $resultsTxtPath -Value "Monitoring started on $($adapter.Name) at $(Get-Date)."
        }

        if ($disconnectCounter -ge 1 -AND $connected) {
            $script:reconnectTime = Get-Date
            $timeWhileDisconnected = New-TimeSpan -Start $disconnectTime -End $reconnectTime
            $timeWhileDisconnected = $timeWhileDisconnected.ToString("dd' days 'hh' hours 'mm' minutes and 'ss' seconds'")
            Write-Host "Reconnected at $time." -ForegroundColor Green
            Add-Content -Path $resultsTxtPath -Value "`n$($adapter.Name) reconnected at $(Get-Date)."
            Add-Content -Path $resultsTxtPath -Value "Disconnected for $timeWhileDisconnected"
        }

        if ($disconnectCounter -eq 1) {
            $script:disconnectTime = Get-Date
            Write-Host "Disconnected at $time." -ForegroundColor Red
            Add-Content -Path $resultsTxtPath -Value "`n$($adapter.Name) disconnected at $(Get-Date)."
        }
    }
}

$script:disconnectCounter = 0
$script:startMonitor = $false
$script:connected = $false
#Function to update adapter NetConenctionStatus values and show status in terminal
Function monitorAdapter {
    $timeLeft = getTimeLeft($monitorLength)
    getAdapters #update wifi adapter variables for next loop through

    $adapterValue = Get-Variable -Name "$answer :*" -ValueOnly

    #If connected, reset disconnect counter and update animation and adapter variables
    if ($adapterValue -eq 2) {
        $script:connected = $true
        Write-Host "Connected" -ForegroundColor Green -NoNewline
        Write-Host " Ctrl+C to QUIT"
        monitorAnimation
        Write-Host "$timeLeft"
        Write-Host ""
        logConnection
        $script:disconnectCounter = 0
    }

    #If disconnected, update disconnect counter, log connection info if necessary, and update adapter variables
    if (-not($adapterValue -eq 2)) {
        $script:connected = $false
        $script:disconnectCounter += 1
        Write-Host "Disconnected." -ForegroundColor Red -NoNewline
        Write-Host " Ctrl+C to QUIT"
        Write-Host "|" -ForegroundColor Red -NoNewline; Write-Host "-XX-" -ForegroundColor Yellow -NoNewline; Write-Host "|" -ForegroundColor Red -NoNewline;
        Write-Host "$timeLeft"
        Write-Host ""
        logConnection
    }
}

#If a variable coresponds with answer (it's not null), run the while loop
if (-not($null -eq (Get-Variable -Name "$answer :*"))) {

    #We've started monitoring, so log monitor start
    logConnection($connectionStart = $true)
    $script:startMonitor = $true

    while ($script:startMonitor) {

        monitorAdapter
        $script:monitorLength -= 1

        #If monitor length time expires end the loop
        if ($script:monitorLength -le 0) {
            $script:startMonitor = $false
            break
        }

        Start-Sleep 1
    }
}

Write-Host ""
Write-Host "Results have been saved to a txt file at $script:resultsTxtPath."
Write-Host ""
    
Start-Process explorer $script:resultsDir