Today, I was listening to some new music, and wanted to add some songs to my playlist on MusicBee (A music manager/mp3 player for Windows). While downloading the music, I thought about the security risk of having all the music I listen to in one single folder on my computer. What if my computer broke? The folder corrupted? Accidentally deleted? After some brainstorming, I had the idea to put my Bash scripting skills (that I have been learning on w3schools.com) to the test. I wanted to be able to backup my playlist quickly and efficiently to a usb stick I have, keeping my playlist secure.

I want to create a script that:
- Copy any files from my Playlist folder to the USB stick (provided they arent already there).
- Delete any files from my USB stick that are no longer in the Playlist folder (Keeping my playlist consistent)

This is the vision as of today. I booted up VScode, and made a script file where the magic will happen.
As of today, here's what I've done: (For context, /mnt/ is Linux's way of mounting my Windows files so that it can access them in scripts; it's the root directory.)

`#!/bin/bash`

`#/mnt/c/Users/zizan/Downloads/code/bash/projects`

`#Written by Adheem Khan`
`#15/5/25 - XX/5/25`

`#Playlist BackerUpper`
`#This script, when executed and my USB stick plugged into my device, will:`
`#Copy any music files in my Playlist folder into my USB (provided they arent already there).`
`#Delete any music files in my USB that arent in the Playlist folder.`

`PLAYLIST_PATH="/mnt/c/Users/zizan/Downloads/Playlist"`
`EXTERNAL_STORAGE_PATH="/mnt/d"`

`cd $EXTERNAL_STORAGE_PATH`
`ls -lh`

(end of code)

`#!/bin/bash`: Makes sure the program knows to interpret the following script as Bash.
`#/mnt/c/Users/zizan/Downloads/code/bash/projects`: The location of the script, in a comment, for convenience when cd'ing to it in my Linux terminal.
`PLAYLIST_PATH="/mnt/c/Users/zizan/Downloads/Playlist"`: Instantiating a variable called PLAYLIST_PATH that allows me to quickly reference the (permanent) location of the playlist where my music is stored locally.
`EXTERNAL_STORAGE_PATH="/mnt/d"`: The same, but for my USB stick (when its plugged in).

Already, I've reached in impasse. when cd'ing to /mnt/d, the Bash shell throws me a 'No such file or directory' error; I can't cd to the USB stick. At this point, i was quite stuck, so i searched up a solution and found this:

`sudo mkdir /mnt/d`: creates a directory at /mnt/d; an empty folder to use as a placeholder where i can access the USB's files in Linux.
`sudo mount -t drvfs D: /mnt/d`: mounts my USB drive (called DriveKnight) into /mnt/d using the drvfs driver, which is how WSL (how im using Linux on Windows) accesses Windows drives, i.e. DriveKnight (D:)

And it works! navigating to it, and using `cd .` displays all the files in my USB stick, which I'll call **DriveKnight** for the remainder of this documentation. So now, we successfully have our paths to the Playlist and the USB mounted and stored in their respective variables. We can move on.

Half of our objective is to be able to copy files from Playlist into DriveKnight that arent already there. To do this, we'll add a line of code that allows me to spot any files that are in Playlist and not DriveKnight, and vice versa; I've written this line of code to do exactly this:

`time diff -q "$PLAYLIST_PATH" "$EXTERNAL_STORAGE_PATH"`

the time command allows me to see how long the command takes to complete after it happens, so i can quantitatively compare the speed of the script now vs later versions. diff -rq outputs the differences in files between Playlist and DriveKnight; the -r prefix does so recursively, going through every subdirectory in both. As of now, the only subdirectory is the Album Cover folder, which is why -r is necessary. the -q prefix outputs only the differences, keeping analysis efficient. and of course, the parameters being the path to Playlist and DriveKnight respectively. Running this gives me the following:

https://github.com/adheem00/Playlist-BackerUpper/blob/main/assets/Pasted%20image%2020250516202730.png

Here we can see the files that are only in Playlist, and the ones only in DriveKnight. the ones only in DriveKnight are ones that have been deleted from the playlist for one reason or another. So, we'll need to delete them from DriveKnight. Tweaking our diff command abit, we can filter for only the files that need to be deleted:

## Saturday, 17th May 2025
`time diff -rq $PLAYLIST_PATH $EXTERNAL_STORAGE_PATH | grep "Only in /mnt/d: "`: the differences are piped into a grep command that filters out lines that dont include `"Only in /mnt/d: "`. This outputs:

https://github.com/adheem00/Playlist-BackerUpper/blob/main/assets/Pasted%20image%2020250517140817.png

Here, we can see a file called 'System Volume Information.' A quick search tells me that it stored metadata and indexing information for faster searches, so I will need to avoid deleting it. I'll tweak our diff command again to filter it out:

`time diff -rq $PLAYLIST_PATH $EXTERNAL_STORAGE_PATH | grep "Only in /mnt/d: " | grep -v "System Volume Information"`

The output for this command is:
https://github.com/adheem00/Playlist-BackerUpper/blob/main/assets/Pasted%20image%2020250517141629.png

Now we'll get an output of every file that needs to be deleted. From here, let's cut down each line, leaving just the name of the file. To do this, i thought i'd add the following code to the end of the diff command:

`| cut --complement -d' ' -f1-3`: a cut command that displays all fields *except* fields 1, 2 and 3. fields are delimited with a space (hence -d' '). the fields in question are 'Only', 'in', 'mnt/d' and the song name. so the first 3 fields would be cut out, leaving just the file name. To be clear, this is the current line of code:

`time diff -rq $PLAYLIST_PATH $EXTERNAL_STORAGE_PATH | grep "Only in /mnt/d: " | grep -v "System Volume Information" | cut --complement -d' ' -f1-3`

Running this gives the output:
https://github.com/adheem00/Playlist-BackerUpper/blob/main/assets/Pasted%20image%2020250517172457.png

As expected, the first 3 fields have been cut, and our output is purely the names of the files that are no longer in Playlist, but remain in DriveKnight. The next step now is to remove them from DriveKnight. To do this, I'm going to create an array where each file name will be stored, then a for loop that deletes each element in the array. I'll do it like this:

`tracks_to_be_deleted=("song1", "song2")`

`for track in "${tracks_to_be_deleted[@]}"; do`

    `echo "$track"`

`done`

i've created an array of tracks to be deleted, and to make sure each element can be looped through, i've written a for loop printing only each element, working as expected:
https://github.com/adheem00/Playlist-BackerUpper/blob/main/assets/Pasted%20image%2020250517191304.png

To actually add each song to the array, I'll use the mapfile command; it reads lines into an array, and can split an output into separate lines, removing the newline character for convenience. Here's what i added to the diff command:

`mapfile -t tracks_to_be_deleted < <(time diff -rq $PLAYLIST_PATH $EXTERNAL_STORAGE_PATH | grep "Only in /mnt/d: " | grep -v "System Volume Information" | cut --complement -d' ' -f1-3)`

or, for more clarity,

`mapfile -t tracks_to_be_deleted < <(command)`

the -t prefix removes any newline characters. it uses process subsitution, in which the command is ran in a 'subshell', and its output fed into the mapfile command, which appends each new line into tracks_to_be_deleted. It's super convenient for the task at hand. Running the entire command gives us the following output:
https://github.com/adheem00/Playlist-BackerUpper/blob/main/assets/Pasted%20image%2020250517192757.png

Yes, i did delete some more music from the Playlist inbetween writeups. Anyway, the code works as expected. each line was appended to the table, and echo'd with no apparent issues. We can now manipulate the for loop to remove each file from DriveKnight and be sure that it's happening. I'll modify the for loop into this:


`DELETION_HISTORY="/mnt/c/Users/zizan/Downloads/deletionhistory.txt"`

`for track in "${tracks_to_be_deleted[@]}"; do

    echo "$track is about to be deleted."

    echo "$track" >> $DELETION_HISTORY

    rm -vi "/mnt/d/$track"

`done`

As you can see, i've added a remove operation to delete each file in our array, adding back its exact path. i've added the prefixes -v and -i to see exactly what's happening, and get a confirmation before doing so incase of any problems. You can also see that i've added the name of each track to a separate file called deletionhistory.txt; this is done so that I have those songs stored one way or another in case I accidentally delete something i didnt want to, or just wanted an old song back, which i could find the name of again. Running this gives us the following output:
https://github.com/adheem00/Playlist-BackerUpper/blob/main/assets/2025-05-18%2018-45-47.mkv

As you can see, it prompted me to confirm-delete each file, which I did. Each file was also written to deletionhistory.txt:

https://github.com/adheem00/Playlist-BackerUpper/blob/main/assets/Pasted%20image%2020250518185150.png
(The highlighted part is from a previous attempt)

This is a huge success! Now I can successfully delete files from DriveKnight that arent in Playlist anymore, making our script about halfway complete. 

## Sunday, 18th May 2025

Moving onto the second half of this script, syncing any files from Playlist that aren't in DriveKnight. to do this, we'll need to find the differences in files between the 2 locations, filter out any that arent exclusively in Playlist, and copy those files into DriveKnight, adding their names to a list for future reference.

To do this, I'll slightly manipulate the diff command I wrote to output files exclusively in DriveKnight, like so:

`tracks_to_update_to_drive=("song1" "song2")`

`mapfile -t tracks_to_update_to_drive < <(time diff -rq $PLAYLIST_PATH $EXTERNAL_STORAGE_PATH | grep "Only in /mnt/c/Users/zizan/Downloads/Playlist: " | grep -v "System Volume Information" | cut --complement -d' ' -f1-3)`

This line searches (recursively) for the differences between Playlist and Driveknight, filtering only files that are in Playlist and not DriveKnight, filters out System Volume Information too, and cuts away the first 3 fields that the diff command would output, namely 'Only', 'in', and '/mnt/c/Users/zizan/Downloads/Playlist'. This leaves us with just the filenames, which the mapfile command takes, and appends it to the tracks_to_update_to_drive array; split line-by-line, and removing any newline characters. Before we use a for loop to copy these files into DriveKnight, I'll make sure everything is working smoothly so far by printing the tracks_to_update_to_drive array after the diff command is complete:

`printf '%s\n' "${tracks_to_update_to_drive[@]}"`

Running these lines, we get the following output:
https://github.com/adheem00/Playlist-BackerUpper/blob/main/assets/Pasted%20image%2020250518191226.png

As expected, the array held every song that hasn't been updated into DriveKnight yet. Now all we need to do is copy them into DriveKnight. I'll do it by modifying the earlier for loop like so:

`ADDITION_HISTORY="/mnt/c/Users/zizan/Downloads/additionhistory.txt"`

`for track in "${tracks_to_update_to_drive[@]}"; do

    echo "$track is about to be added to DriveKnight!"

    echo "$track" >> $ADDITION_HISTORY

    cp "$PLAYLIST_PATH/$track" "$EXTERNAL_STORAGE_PATH"

`done`

These lines loops through each line in the array, appends its name into a new file called additionhistory.txt, then copies the file into DriveKnight. Testing this, our output is as follows:
https://github.com/adheem00/Playlist-BackerUpper/blob/main/assets/Pasted%20image%2020250518194740.png

As you can see, our for loop has worked, and each file has been added to DriveKnight. To double-check, I'll open DriveKnight and look for those files.
https://github.com/adheem00/Playlist-BackerUpper/blob/main/assets/Pasted%20image%2020250518194919.png


Brilliant! This is confirmation that our script is working perfectly. After this command, we can add a second diff command; If we get no output, then we can be sure that Playlist and DriveKnight are successfully synced. The command will be as follows:

`diff -rq $PLAYLIST_PATH $EXTERNAL_STORAGE_PATH`

Fairly self-explanatory; this line shows the differences between the files in the 2 locations; no difference means that our previous manipulations have worked as expected. Running this line, our output is as follows:
https://github.com/adheem00/Playlist-BackerUpper/blob/main/assets/Pasted%20image%2020250518195858.png

Here, the only differences between the 2 locations are some sub-folders in the Album Covers directory, a difference in sync.ffs_db (which is part of the FreeFileSync software, that allows you to sync the contents of 2 locations, which is what inspired this script), and System Volume Information; we can ignore sync.ffs_db and System Volume Information, and the Album Covers directory for now. I'll perhaps deal with the Album Covers directory in a later addition to the script.

As for right now, no music files were different in either location, meaning that our script is complete! Running it once allows me to completely sync Playlist and DriveKnight, ensuring my playlists' safety incase of corruption, or anything else.

To be as sure as possible, I'll manually add some new music files into Playlist, and delete some from Playlist too. This way, I can test if each part of the script is working. I've added 4 files, 2 to Playlist called song1.mp3 and song2.mp3, and 2 to DriveKnight called song3.mp3 and song4.mp3. Let's run the following script now, and analyse our output. Before doing this, I've modified the diff command at the end to filter away information about the Album Covers directory, sync.ffs_db, and System Volume Information. My intent here is to test if the script in its current state deals with files in the way I intend it to:

`diff -rq "$PLAYLIST_PATH" "$EXTERNAL_STORAGE_PATH" | grep -Ev "System Volume Information|sync\.ffs_db|Only in .*/Album Covers:"`

And here's the current state of the script (screenshotted due to formatting issues):
https://github.com/adheem00/Playlist-BackerUpper/blob/main/assets/Pasted%20image%2020250518201542.png


Running this script, our output is as follows:
https://github.com/adheem00/Playlist-BackerUpper/blob/main/assets/showcase%20test%201.mov

Some notes about this video: First, i cut it down abit because it takes about 12 minutes (4~ minutes per diff command). Secondly, the reason a line mentioning the Album Covers directory came up despite the filter was because my filter included a colon : after the 's' in Album Covers, so it wouldn't have filtered as expected.

Aside from that, song1 and song2.mp3 were indeed added to DriveKnight, as well as additionhistory.txt. song3 and song4.mp3 were removed from DriveKnight, and their names added to deletionhistory.txt. Screenshots below to prove this:


https://github.com/adheem00/Playlist-BackerUpper/blob/main/assets/Pasted%20image%2020250518204535.png

https://github.com/adheem00/Playlist-BackerUpper/blob/main/assets/Pasted%20image%2020250518204552.png

https://github.com/adheem00/Playlist-BackerUpper/blob/main/assets/Pasted%20image%2020250518204612.png

This is confirmation that my script is working exactly as expected, except the final diff command, which I'll modify like so:

`diff -rq "$PLAYLIST_PATH" "$EXTERNAL_STORAGE_PATH" | grep -Ev "System Volume Information|sync\.ffs_db|Only in .*/Album Covers"`: removed the colon.

And that's about it. Thanks for reading! I'll be updating this script in the future if need be. The final (current) script will be in this repo.
