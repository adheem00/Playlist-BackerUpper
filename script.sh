#!/bin/bash

# /mnt/c/Users/adhee/Downloads/Programming/Code/Bash/Projects

# Written by Adheem Khan
# 15/5/25 - 18/5/25

# Playlist BackerUpper
# This script, when executed and my USB stick plugged into my device, will:
# Copy any music files in my Playlist folder into my USB (provided they arent already there).
# Delete any music files in my USB that arent in the Playlist folder.


sudo mount -t drvfs D: /mnt/d/

PLAYLIST_PATH="/mnt/c/Users/adhee/Downloads/Music/Playlist"
EXTERNAL_STORAGE_PATH="/mnt/d/BackupPlaylist"

DELETION_HISTORY="/mnt/c/Users/adhee/Downloads/Music/deletionhistory.txt"
ADDITION_HISTORY="/mnt/c/Users/adhee/Downloads/Music/additionhistory.txt"

tracks_to_be_deleted=()
tracks_to_update_to_drive=()


# Removing Files from DriveKnight
mapfile -t tracks_to_be_deleted < <(time diff -rq $PLAYLIST_PATH $EXTERNAL_STORAGE_PATH | grep "Only in /mnt/d/BackupPlaylist:" | \
grep -v "System Volume Information" | cut --complement -d' ' -f1-3)

for track in "${tracks_to_be_deleted[@]}"; do
    echo "$track is about to be deleted."
    
    echo "$track" >> $DELETION_HISTORY
    rm -vi "/mnt/d/$track"
done

echo "All inconsistent files have been removed from DriveKnight."
echo "Beginning to update files to DriveKnight..."

# Adding Files TO DriveKnight
mapfile -t tracks_to_update_to_drive < <(
    diff -rq "$PLAYLIST_PATH" "$EXTERNAL_STORAGE_PATH" |
    grep "Only in $PLAYLIST_PATH:" |
    grep -v "System Volume Information" |
    sed "s|Only in $PLAYLIST_PATH: ||"
)

for track in "${tracks_to_update_to_drive[@]}"; do
    echo "$track is being added to DriveKnight!"
    
    echo "$track" >> $ADDITION_HISTORY
    cp "$PLAYLIST_PATH/$track" "$EXTERNAL_STORAGE_PATH"
done

# Final diff command to check for any anomalies
diff -rq "$PLAYLIST_PATH" "$EXTERNAL_STORAGE_PATH" | grep -Ev "System Volume Information|sync\.ffs_db"

echo "Done!"


