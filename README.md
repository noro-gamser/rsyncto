This script, rsyncto_ultra.sh, is designed to synchronize data from a source folder to a destination folder using the rsync command. It also performs hash checks on the transferred data in the destination folder and optionally deletes files in the source folder based on the hashsum in the destination folder. The script reads its configuration from a separate .conf file.

Here's a high-level description of the script's functionality:

Load Configuration: The script loads its configuration from the rsyncto_ultra.conf file, which contains parameters such as source and destination folder paths, bandwidth limits, ping test thresholds, etc.

Time and Bandwidth Limit: It performs a ping test to determine the current ping time. Based on the ping time, it calculates the bandwidth limit for the data transfer using the get_bwlimit() function.

Data Transfer: The script uses the rsync command with the calculated bandwidth limit to transfer data from the source folder to the destination folder. The transfer progress and any errors are logged to files (rsync_log.txt and rsync_error_log.txt).

Partial Hash Check: After the data transfer, the script performs a partial hash check on subfolders that have been processed. It keeps track of the processed subfolders using the processed_subfolders array. The partial_hash_check() function reads the hash file (hashes.md5) in the destination folder and compares the hashes of transferred files in the processed subfolders. It reports any failed hash checks.

Hash Check: If the CHECK_HASH flag is set to true in the configuration, the script performs a full hash check on all files in the destination folder. It compares the hashes of the transferred files with the original source files to ensure data integrity. The results of the hash check are logged to the rsync_log.txt and rsync_error_log.txt files.

Automatic Deletion: If the automatisches_loeschen flag is set to true in the configuration, the script deletes files in the source folder with correct hashsums. This is to ensure that only successfully transferred files are deleted from the source folder. The delete_files() function is a placeholder for custom logic to handle the actual file deletion.

Main Function: The main() function orchestrates the entire process by calling the necessary functions in the defined order.

The script allows for flexible configuration using the .conf file, making it adaptable to different synchronization scenarios. It provides options to customize bandwidth limits, hash checks, and automatic deletion, making it a versatile tool for data synchronization with data integrity checks.
