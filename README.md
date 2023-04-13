# NetAdapterMonitor-Powershell
Powershell script to monitor a network adapter every second until it disconnects.
Run this script on a local machine to monitor a network adapter's connection status every second.
You can run this script on a remote machine as well with: Invoke-Command -ComputerName $Computer -FilePath $scriptPath.
Windows Remote Management will need to be enabled on the remote machine to run the script remotely.
Results are logged to a txt file in the current user's documents directory.

This script could be useful for when a user claims their wireless keeps disconnecting but you don't have time to sit and watch it for 5-10+ minutes.
