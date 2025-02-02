# Define the path to the configuration file
$configPath = "$env:USERPROFILE\.trash-compactor\config.ps1"

# Create a default config file if it does not exist
if (-Not (Test-Path -Path $configPath)) {
    New-Item -ItemType Directory -Path (Split-Path $configPath) -Force
    @"
`$sourceFolder = `"$env:USERPROFILE\Downloads\"
`$destinationZip = `"$env:USERPROFILE\Trash Compactor\"
`$versionsToKeep = 5
"@ | Out-File -FilePath $configPath -Encoding UTF8
}

# Import the configuration file
. $configPath

# Ensure the destination folder exists
if (-Not (Test-Path -Path $destinationZip)) {
    New-Item -ItemType Directory -Path $destinationZip -Force
}

# Get the current date and time
$currentDateTime = Get-Date -Format "yyyyMMdd_HHmm"
$destinationZip = $destinationZip + "Archive_$currentDateTime.zip"

# Create a new zip file
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($sourceFolder, $destinationZip)

Write-Output "All files in $sourceFolder have been moved to $destinationZip"

# Remove all files and subfolders in the source folder
Get-ChildItem -Path $sourceFolder -Recurse -File | Remove-Item -Force -Recurse
Get-ChildItem -Path $sourceFolder -Recurse -Directory | Remove-Item -Force -Recurse


Write-Output "All files in $sourceFolder have been moved to $destinationZip and deleted from the source folder"

# Keep only the specified number of recent zip files in the destination folder
$zipFiles = Get-ChildItem -Path (Split-Path $destinationZip) -Filter "*.zip" | Sort-Object LastWriteTime -Descending
if ($zipFiles.Count -gt $versionsToKeep) {
    $zipFiles[$versionsToKeep..$zipFiles.Count] | Remove-Item -Force
}

Write-Output "Only the $versionsToKeep most recent zip files are kept in the destination folder"


# Create a copy of the current running script in the .trash-compactor folder
$scriptPath = $MyInvocation.MyCommand.Path
$destinationScriptPath = "$env:USERPROFILE\.trash-compactor\TrashCompactor.ps1"
Copy-Item -Path $scriptPath -Destination $destinationScriptPath -Force

Write-Output "A copy of the script has been created in the .trash-compactor folder"