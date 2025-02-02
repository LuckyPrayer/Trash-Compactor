#!/bin/bash

# Check for the install argument
action=$1

function install_trash_compactor {
    # Check if the script is running with elevated privileges
    if [ "$EUID" -ne 0 ]; then
        echo "Please run this script as an administrator."
        exit
    fi

    # Define the path to the configuration file
    config_path="$HOME/.trash-compactor/config.sh"

    # Prompt user for configuration values
    read -p "Enter the source folder path (default: $HOME/Downloads/): " source_folder
    source_folder=${source_folder:-"$HOME/Downloads/"}

    read -p "Enter the destination folder path (default: $HOME/Trash Compactor/): " destination_zip
    destination_zip=${destination_zip:-"$HOME/Trash Compactor/"}

    read -p "Enter the number of versions to keep (default: 5): " versions_to_keep
    versions_to_keep=${versions_to_keep:-5}

    # Create a default config file if it does not exist
    if [ ! -f "$config_path" ]; then
        mkdir -p "$(dirname "$config_path")"
        cat <<EOL > "$config_path"
source_folder="$source_folder"
destination_zip="$destination_zip"
versions_to_keep=$versions_to_keep
EOL
    fi

    # Ensure the destination folder exists
    mkdir -p "$destination_zip"

    # Create a copy of the current running script in the .trash-compactor folder
    script_path=$(realpath "$0")
    destination_script_path="$HOME/.trash-compactor/TrashCompactor.sh"
    cp "$script_path" "$destination_script_path"

    # Ask user if they want to create a cron job
    read -p "Do you want to create a cron job to run this script weekly? (yes/no): " create_task
    if [ "$create_task" == "yes" ]; then
        (crontab -l 2>/dev/null; echo "0 9 * * 1 bash $destination_script_path") | crontab -
        echo "Trash Compactor has been installed, configured, and scheduled to run weekly."
    else
        echo "Trash Compactor has been installed and configured."
    fi
}

function uninstall_trash_compactor {
    # Define the path to the configuration file
    config_path="$HOME/.trash-compactor/config.sh"

    # Remove the configuration file and the .trash-compactor directory
    if [ -f "$config_path" ]; then
        rm -rf "$(dirname "$config_path")"
        echo "Trash Compactor has been uninstalled and configuration removed."
    else
        echo "Trash Compactor is not installed."
    fi

    # Remove the cron job
    crontab -l | grep -v "bash $HOME/.trash-compactor/TrashCompactor.sh" | crontab -
    echo "Cron job for Trash Compactor has been removed."
}

if [ "$action" == "install" ]; then
    install_trash_compactor
    exit
elif [ "$action" == "uninstall" ]; then
    uninstall_trash_compactor
    exit
fi

# Import the configuration file
config_path="$HOME/.trash-compactor/config.sh"
source "$config_path"

# Ensure the destination folder exists
mkdir -p "$destination_zip"

# Get the current date and time
current_date_time=$(date +"%Y%m%d_%H%M%S")
destination_zip="$destination_zip/Archive_$current_date_time.zip"

# Create a new zip file
zip -r "$destination_zip" "$source_folder"

echo "All files in $source_folder have been moved to $destination_zip"

# Remove all files and subfolders in the source folder
rm -rf "$source_folder"/*

echo "All files and subfolders in $source_folder have been deleted"

# Keep only the specified number of recent zip files in the destination folder
zip_files=($(ls -t "$destination_zip"/*.zip))
if [ ${#zip_files[@]} -gt $versions_to_keep ]; then
    for ((i=$versions_to_keep; i<${#zip_files[@]}; i++)); do
        rm -f "${zip_files[$i]}"
    done
fi

echo "Only the $versions_to_keep most recent zip files are kept in the destination folder"