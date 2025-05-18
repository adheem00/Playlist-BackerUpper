#!/bin/bash

# /mnt/c/Users/zizan/Downloads/code/bash/projects

# Written by Adheem Khan
# 15/5/25 - 18/5/25

# Playlist BackerUpper
# This script, when executed and my USB stick plugged into my device, will:
# Copy any music files in my Playlist folder into my USB (provided they arent already there).
# Delete any music files in my USB that arent in the Playlist folder.

sudo mount -t drvfs D: /mnt/d

PLAYLIST_PATH="/mnt/c/Users/zizan/Downloads/Playlist"
EXTERNAL_STORAGE_PATH="/mnt/d"

DELETION_HISTORY="/mnt/c/Users/zizan/Downloads/deletionhistory.txt"
ADDITION_HISTORY="/mnt/c/Users/zizan/Downloads/additionhistory.txt"

tracks_to_be_deleted=("song1" "song2")
tracks_to_update_to_drive=("song1" "song2")


# Removing Files from DriveKnight
mapfile -t tracks_to_be_deleted < <(time diff -rq $PLAYLIST_PATH $EXTERNAL_STORAGE_PATH | grep "Only in /mnt/d: " | \
grep -v "System Volume Information" | cut --complement -d' ' -f1-3)

for track in "${tracks_to_be_deleted[@]}"; do
    echo "$track is about to be deleted."
    
    echo "$track" >> $DELETION_HISTORY
    rm -vi "/mnt/d/$track"
done

echo "All inconsistent files have been removed from DriveKnight."
echo "Beginning to update files to DriveKnight..."

# Adding Files TO DriveKnight
mapfile -t tracks_to_update_to_drive < <(time diff -rq $PLAYLIST_PATH $EXTERNAL_STORAGE_PATH | \
grep "Only in /mnt/c/Users/zizan/Downloads/Playlist: " | grep -v "System Volume Information" | cut --complement -d' ' -f1-3)

printf '%s\n' "${tracks_to_update_to_drive[@]}"

for track in "${tracks_to_update_to_drive[@]}"; do
    echo "$track is about to be added to DriveKnight!"
    
    echo "$track" >> $ADDITION_HISTORY
    cp "$PLAYLIST_PATH/$track" "$EXTERNAL_STORAGE_PATH"
done


diff -rq "$PLAYLIST_PATH" "$EXTERNAL_STORAGE_PATH" | grep -Ev "System Volume Information|sync\.ffs_db|Only in .*/Album Covers"


