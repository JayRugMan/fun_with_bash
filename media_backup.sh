#!/bin/bash
# This script is for backing up media from the a source directory.
# The idea is to have it check weekly which files have been added 
# since the last tarball was creted, then create a new tarball with 
# only the new files included.

PATH=/usr/local/sbin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin

THEDATE=$(date +%Y%m%d-%H%M)

### Customize Here ###

SOURCE_DIR="/home/plex"
TARGET_DIR="/mnt/backups"
ARCHIVE_FILE="$TARGET_DIR/media_backups_plex01_$THEDATE.tgz"
LOGFILE="/mnt/backups/media_bu.log"

### End Customization ###


# creates log file if it does not exist already
if [[ ! -f $LOGFILE ]] ; then touch $LOGFILE; fi

# Get's the last archive file for time comparison in find command
LATEST_BU="$(ls -1t $TARGET_DIR | grep media_backups_plex01 | head -1)"


function get_new_files() {
  # Checks if there are any new files that need backing up and echos a list of them 
  # with quotes so filenames with spaces and other characters can still be included
  IFS=$'\n'
  for i in $(find . -type f -newer $TARGET_DIR/$LATEST_BU -not -iname "*.rpm"); do 
    echo -n "\"$i\" "
  done
  unset IFS
}


function main() {
  # Main Function
  cd $SOURCE_DIR
  filesString="$(get_new_files)"
  if [[ -z $filesString ]]; then 
    exit 1
  else
    echo "$THEDATE:  Starting Backup" >> $LOGFILE
    echo "tar czf $ARCHIVE_FILE $filesString" | /bin/sh
    if [[ $? -eq 0 ]]; then
      echo "successfully archived the following files into $ARCHIVE_FILE:" >> $LOGFILE
      printf "$(echo "$filesString" | sed 's/^"//g;s/" "/\\n/g;s/"//g')\n\n" >> $LOGFILE
    else
      echo "Backup failed" >> $LOGFILE
    fi
  fi
}

main
