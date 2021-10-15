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
PLEX_CONF_SRC_DIR="/var/lib/plexmediaserver/Library/Application*Support/"
PLEX_CONF_TGT_DIR="/mnt/backups/configs/plex"
PLEX_CONF_ARCHIVE_FILE="Plex_Media_Server_configs_$THEDATE.tgz"
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


function media_backup() {
  # Media backup Function
  cd $SOURCE_DIR
  filesString="$(get_new_files)"
  if [[ -z $filesString ]]; then 
    exit 1
  else
    echo "$THEDATE:  Starting media file backup" >> $LOGFILE
    echo "tar czf $ARCHIVE_FILE $filesString" | /bin/sh
    if [[ $? -eq 0 ]]; then
      echo "successfully archived the following files into $ARCHIVE_FILE:" >> $LOGFILE
      printf "$(echo "$filesString" | sed 's/^"//g;s/" "/\\n/g;s/"//g')\n\n" >> $LOGFILE
    else
      echo -e "Media file backup failed\n" >> $LOGFILE
    fi
  fi
}


function config_backup() {
  # Plex Configuration Backup function
  cd $PLEX_CONF_SRC_DIR
  echo "$THEDATE:  Starting Plex Media Server configuration backup" >> $LOGFILE
  echo "tar czf $PLEX_CONF_TGT_DIR/$PLEX_CONF_ARCHIVE_FILE Plex\ Media\ Server/" | /bin/sh
  if [[ $? -eq 0 ]]; then
    echo -e "successfully archived Plex Media Server configurations into $PLEX_CONF_TGT_DIR/$PLEX_CONF_ARCHIVE_FILE\n" >> $LOGFILE
  else
    echo -e "Plex Media Server configuration backup failed\n" >> $LOGFILE
  fi
}


function main() {
  # Main Function
  media_backup
  config_backup
}

main
