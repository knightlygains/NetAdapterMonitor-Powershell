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
Write-Host " _ _ _ _ ___ _    _____         _ _           
| | | |_|  _|_|  |     |___ ___|_| |_ ___ ___ 
| | | | |  _| |  | | | | . |   | |  _| . |  _|
|_____|_|_| |_|  |_|_|_|___|_|_|_|_| |___|_|  
"
Write-Host "This script is used to monitor a wireless adapter's connection every second, and then log the date and time the second it is found to be disconnected."
Write-Host ""

Function getWifis {
    #Variable that allows us to loop through and get all adapters with 'Wi' in the name.
    $global:adapters = Get-CimInstance -Class Win32_NetworkAdapter -Filter "Name like '%Wi%'" | Select-Object Name, deviceID, NetConnectionStatus

    #Loop through adapters and create/update variables for each one.
    foreach ($adapter in $adapters) {
        #"$($adapter.deviceID) : $($adapter.name) : $($adapter.NetConnectionStatus)"
        Set-Variable -Name "$($adapter.deviceID): wifi:$($adapter.Name)" -Value $adapter.NetConnectionStatus -Scope global #create variable

        # $thisVariableValue = Get-Variable -Name "$($adapter.deviceID)*" -ValueOnly
        # $thisVariable = Get-Variable -Name "$($adapter.deviceID)*"
    }
}

$script:monitorCount = 1 #Variable to track step in animation
$script:incline = $true #Variable to track direction animation should go in

Function monitorAnimation {
    if ($monitorCount -eq 1) {
        Write-Host "|" -ForegroundColor Yellow -NoNewline;
        Write-Host "-   |" -NoNewline; Write-Host "Time-$time"
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
        Write-Host "| -  |" -NoNewline; Write-Host "Time-$time"
        if ($incline) {
            $script:monitorCount += 1
        }
        else {
            $script:monitorCount -= 1
        }
        return
    }
    if ($monitorCount -eq 3) {
        Write-Host "|  - |" -NoNewline; Write-Host "Time-$time"
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
        Write-Host "|" -ForegroundColor Green -NoNewline; Write-Host "Time-$time"
        $script:incline = $false
        $script:monitorCount -= 1
        return
    }
}

#Get wifi adapters and create/update variables made from them.
getWifis

#Variable that will allow us to loop through the variables we made in the function getWifis
$wifiVariables = Get-Variable -Name "*wifi*"

Write-Host ""

foreach ($wifi in $wifiVariables) {
    if ($($wifi.value) -eq 2) {
        Write-Host "$($wifi.Name) is connected!" -ForegroundColor Green
    }
    else {
        Write-Host "$($wifi.Name) is disconnected..." -ForegroundColor Red
    }
}
Write-Host ""

$answer = Read-Host "Select a wifi device to monitor. Enter the number seen before 'wifi'"
Write-Host ""

if (-not(Get-Variable -Name "$answer*")) {
    Write-Host "Invalid Wifi adpater selection"
    break
}
else {
    $wifiAdapter = Get-Variable -Name "$answer*" #Get variable that corresponds with our answer
    if (-not($wifiAdapter.Value -eq 2)) {
        Write-Host "Device is disconnected. No monitoring necessary."
        Write-Host ""
        break
    }
    else {
        Write-Host "Monitoring $($wifiAdapter.Name)."
        Write-Host "Monitoring will begin in 5 seconds and check every second for connection status."
        Write-Host ""
        Start-Sleep 5
    }
}

$script:time = Get-Date -Format HH:mm:ss

#If a variable coresponds with answer (not null), run the while loop
if (-not($null -eq (Get-Variable -Name "$answer*"))) {
    while ((Get-Variable -Name "$answer*" -ValueOnly) -eq 2) {
        $time = Get-Date -Format HH:mm:ss
        Write-Host "Connected" -ForegroundColor Green -NoNewline
        Write-Host " Ctrl+C to QUIT"
        monitorAnimation
        Write-Host ""
        Start-Sleep 1
        getWifis #update wifi adapter variables for next loop through
    }
    if (-not((Get-Variable -Name "$answer*" -ValueOnly) -eq 2)) {
        Write-Host "Disconnected at $time." -ForegroundColor Red
        Write-Host "|" -ForegroundColor Red -NoNewline; Write-Host "-XX-" -ForegroundColor Yellow -NoNewline; Write-Host "|" -ForegroundColor Red;
        Write-Host ""
    }
}

if (-not($null -eq (Get-Variable -Name "$answer*"))) {
    #Get current user's documents folder
    $userDocuments = [Environment]::GetFolderPath("MyDocuments")
    # Write-Host "$userDocuments"
    $resultsDir = "$userDocuments\WifiMonitorResults"
    $resultsTxtPath = "$resultsDir\WifiMonitorResults.txt"

    if (Test-Path $resultsDir) {
        #If directory already exists
        try {
            New-item -Path $resultsDir -Name "WifiMonitorResults.txt" -ItemType "file" -ErrorAction Stop
        }
        catch {
            Write-Host "Results txt file already exists. Content overwritten."
        }
    
    }
    else {
        #Make the directory and the txt file
        mkdir $resultsDir
        New-item -Path $resultsDir -Name "WifiMonitorResults.txt" -ItemType "file"
    }

    $wifiAdapter = Get-Variable -Name "$answer*"

    Set-Content -Path $resultsTxtPath -Value "$($wifiAdapter.Name) was disconnected at $(Get-Date)"

    Write-Host ""
    Write-Host "Results have been saved to a txt file at $resultsTxtPath."
    Write-Host ""

    Start-Process explorer $resultsDir
}

#Set-Variable -Name "$($adapter.deviceID)*" -Value $adapter.NetConnectionStatus