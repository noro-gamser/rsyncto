#!/bin/bash

# rsyncto_ultra.sh - Synchronizes data from a source folder to a destination folder using rsync
# This script also checks and deletes files in the source folder based on hashsum in the destination folder.

# Global variables
config_file="rsyncto_ultra.conf"
hash_file="hashes.md5"
log_file="rsync_log.txt"
error_log_file="rsync_error_log.txt"
processed_subfolders=()

# Function to load configuration from the config file
load_config() {
    if [ -f "$config_file" ]; then
        source "$config_file"
    else
        echo "Error: Config file $config_file not found."
        exit 1
    fi
}

# Function to convert time in HH:MM format to minutes since midnight
convert_to_minutes() {
    IFS=: read hours minutes <<< "$1"
    echo "$((hours * 60 + minutes))"
}

# Function to get the current time in minutes since midnight
get_current_time() {
    date +%H:%M
}

# Function to get the bandwidth limit based on ping time or night mode
get_bwlimit() {
    local ping_time=$1
    local ping_time_int=$(convert_to_minutes "$ping_time")
    local current_time=$(get_current_time)
    local current_time_int=$(convert_to_minutes "$current_time")

    # Check if night mode is active and within the specified time range
    if [ "$NIGHT_MODE" = true ] && [[ "$current_time_int" -ge "$(convert_to_minutes "$night_start")" || "$current_time_int" -lt "$(convert_to_minutes "$night_stop")" ]]; then
        echo "$bwlimit_night"
        return
    fi

    if [ -n "${ping_stufen[@]}" ]; then
        for (( i = 0; i < ${#ping_stufen[@]}; i++ )); do
            # Validate if ping_time_int is a number before using numeric comparison
            if [[ "$ping_time_int" =~ ^[0-9]*$ ]] && (( ping_time_int < $(convert_to_minutes "${ping_stufen[i]}") )); then
                echo "${bwlimit_stufen[i]}"
                return
            fi
        done
    fi

    echo "$bwlimit_default"
}

# Function to perform partial hash check on subfolders that have been processed
partial_hash_check() {
    local subfolder=$1

    if [[ " ${processed_subfolders[@]} " =~ " $subfolder " ]]; then
        echo "Performing partial hash check for subfolder: $subfolder"
        cd "$ziel/$subfolder" || return
        md5sum -c "$hash_file" 2>/dev/null | grep -v 'OK$' | cut -d':' -f1 | while read -r file; do
            echo "Hash check failed for $file"
            # Add your custom logic here for handling failed hash checks on specific files
        done
        cd - || return
    else
        processed_subfolders+=("$subfolder")
    fi
}

# Function to synchronize data using rsync
sync_data() {
    local source_folder=$1
    local destination_folder=$2

    echo "Transferring data from $source_folder to $destination_folder..."
    rsync --bwlimit="$(get_bwlimit "$ping_time")" -avz "$source_folder" "$destination_folder" >> "$log_file" 2>> "$error_log_file"

    # Perform partial hash check on subfolders
    IFS= find "$source_folder" -type d | while read -r subfolder; do
        subfolder=${subfolder#$source_folder} # Remove the source folder prefix
        partial_hash_check "$subfolder"
    done
}

# Function to delete files in the source folder based on hashsum in the destination folder
delete_files() {
    if [ "$automatisches_loeschen" = true ]; then
        echo "Deleting files in the source folder with correct hashsum..."
        # Add your custom logic here for deleting files in the source folder
    else
        echo "Automatic deletion is disabled."
    fi
}

# Function to check the hashsums in the destination folder
check_hash() {
    if [ "$CHECK_HASH" = true ]; then
        echo "Checking hashsums in destination folder..."
        cd "$ziel" || return
        md5sum -c "$hash_file" >> "$log_file" 2>> "$error_log_file"
        cd - || return
    else
        echo "Hash check is disabled."
    fi
}

# Main function
main() {
    load_config

    # Synchronize data using rsync
    sync_data "$quelle" "$ziel"

    # Check hashsums in the destination folder
    check_hash

    # Delete files in the source folder
    delete_files
}

# Run the main function
main
