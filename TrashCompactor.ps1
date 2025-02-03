# Check for the install argument
param (
    [string]$action
)

function Install-TrashCompactor {

    # Define the path to the configuration file
    $configPath = "$env:USERPROFILE\.trash-compactor\config.ps1"

    # Prompt user for configuration values
    $sourceFolder = Read-Host "Enter the source folder path (default: $env:USERPROFILE\Downloads\)"
    if (-Not $sourceFolder) { $sourceFolder = "$env:USERPROFILE\Downloads\" }

    $destinationZip = Read-Host "Enter the destination folder path (default: $env:USERPROFILE\Trash Compactor\)"
    if (-Not $destinationZip) { $destinationZip = "$env:USERPROFILE\Trash Compactor\" }

    $versionsToKeep = Read-Host "Enter the number of versions to keep (default: 5)"
    if (-Not $versionsToKeep) { $versionsToKeep = 5 }

    # Create a default config file if it does not exist
    if (-Not (Test-Path -Path $configPath)) {
        New-Item -ItemType Directory -Path (Split-Path $configPath) -Force
        @"
`$sourceFolder = `"$sourceFolder"
`$destinationZip = `"$destinationZip"
`$versionsToKeep = $versionsToKeep
"@ | Out-File -FilePath $configPath -Encoding UTF8
    }

    # Ensure the destination folder exists
    if (-Not (Test-Path -Path $destinationZip)) {
        New-Item -ItemType Directory -Path $destinationZip -Force
    }

    # Create a copy of the current running script in the .trash-compactor folder
    $scriptPath = "$PSScriptRoot\TrashCompactor.ps1"
    $destinationScriptPath = "$env:USERPROFILE\.trash-compactor\TrashCompactor.ps1"
    Copy-Item -Path $scriptPath -Destination $destinationScriptPath -Force

    # Ask user if they want to create a scheduled task
    Write-Host "A scheduled task can be created to run this script weekly. Administrator privileges are required. See docs for more information."
    $createTask = Read-Host "Do you want to create a scheduled task to run this script weekly? (yes/no)"
    if ($createTask -eq "yes") {

        # Check if the script is running with elevated privileges
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        if (-Not $isAdmin) {
            Write-Host ""
            Write-Host "Error - This script requires administrator privileges to create a scheduled task." -ForegroundColor Red
            Write-Host "Please run this script again as an administrator. See docs for more information."
            Write-Host "Trash Compactor has been installed and configured without a scheduled task."
            exit
        }

        # Create a scheduled task to run the script every week
        $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File `"$destinationScriptPath`""
        $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At 9am
        $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
        Register-ScheduledTask -TaskName "TrashCompactor" -Action $action -Trigger $trigger -Principal $principal -Settings $settings

        Write-Host "Trash Compactor has been installed, configured, and scheduled to run weekly."
    } else {
        Write-Host "Trash Compactor has been installed and configured."
    }
}

function Uninstall-TrashCompactor {
    # Define the path to the configuration file
    $configPath = "$env:USERPROFILE\.trash-compactor\config.ps1"

    # Check if the configuration file exists before removing it
    if (Test-Path -Path $configPath) {

        # Check if the scheduled task exists before removing it
        $taskExists = Get-ScheduledTask -TaskName "TrashCompactor" -ErrorAction SilentlyContinue
        if ($taskExists) {

        # Check if the script is running with elevated privileges
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        if (-Not $isAdmin) {
            Write-Host ""
            Write-Host "Error - This script requires administrator privileges to remove scheduled task." -ForegroundColor Red
            Write-Host "Please run this script again as an administrator. See docs for more information."
            exit
        }

            Unregister-ScheduledTask -TaskName "TrashCompactor" -Confirm:$false
            Write-Host "Scheduled task for Trash Compactor has been removed."
            } else {
                Write-Host "Scheduled task for Trash Compactor does not exist."
        }
        # Remove the configuration file and the .trash-compactor directory
        Remove-Item -Path (Split-Path $configPath) -Recurse -Force
        Write-Host "Trash Compactor has been uninstalled and configuration removed."

    } else {
        Write-Host "Trash Compactor is not installed."
    }

}

if ($action -eq "install") {
    Install-TrashCompactor
    exit
} elseif ($action -eq "uninstall") {
    Uninstall-TrashCompactor
    exit
}

# Import the configuration file
$configPath = "$env:USERPROFILE\.trash-compactor\config.ps1"
. $configPath

# Ensure the destination folder exists
if (-Not (Test-Path -Path $destinationZip)) {
    New-Item -ItemType Directory -Path $destinationZip -Force
}

# Get the current date and time
$currentDateTime = Get-Date -Format "yyyy-MM-dd_HHmm"
$destinationZip = $destinationZip+"Archive_$currentDateTime.zip"

# Create a new zip file
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($sourceFolder, $destinationZip)

Write-Host "All files in $sourceFolder have been moved to $destinationZip"

# Remove all files and subfolders in the source folder
Get-ChildItem -Path $sourceFolder -Recurse -File | Remove-Item -Force
Get-ChildItem -Path $sourceFolder -Recurse -Directory | Remove-Item -Force

Write-Host "All files and subfolders in $sourceFolder have been deleted"

# Keep only the specified number of recent zip files in the destination folder
$zipFiles = Get-ChildItem -Path (Split-Path $destinationZip) -Filter "*.zip" | Sort-Object LastWriteTime -Descending
if ($zipFiles.Count -gt $versionsToKeep) {
    $zipFiles[$versionsToKeep..($zipFiles.Count - 1)] | ForEach-Object { Remove-Item -Path $_.FullName -Force }
}

Write-Host "Only the $versionsToKeep most recent zip files are kept in the destination folder"