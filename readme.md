# Trash Compactor

Trash Compactor is a PowerShell script that compresses files from a specified source folder into a zip file and moves it to a destination folder. It also provides options to install and uninstall the script, including creating a scheduled task to run the script weekly.

## Features

- Compress files from a source folder into a zip file.
- Move the zip file to a destination folder.
- Keep only a specified number of recent zip files in the destination folder.
- Install and configure the script.
- Optionally create a scheduled task to run the script weekly.
- Uninstall the script and remove the scheduled task.

## Prerequisites

- Windows PowerShell
- Administrator privileges (for creating/removing scheduled tasks)

## Installation

1. Open PowerShell as an administrator.
2. Run the script with the `install` argument:

    ```powershell
    .\TrashCompactor.ps1 -action install
    ```

3. Follow the prompts to configure the source folder, destination folder, and the number of versions to keep.
4. Optionally, choose to create a scheduled task to run the script weekly.

## Uninstallation

1. Open PowerShell as an administrator.
2. Run the script with the `uninstall` argument:

    ```powershell
    .\TrashCompactor.ps1 -action uninstall
    ```

3. The script will remove the scheduled task (if it exists) and delete the configuration file and the `.trash-compactor` directory.

## Usage

To manually run the script, simply execute it without any arguments:

```powershell
.\TrashCompactor.ps1