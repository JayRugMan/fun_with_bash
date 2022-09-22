#!/bin/bash
# This script is for backing up media from the a source directory.
# The idea is to have it check weekly which files have been added 
# since the last tarball was creted, then create a new tarball with 
# only the new files included.

PATH=/usr/local/sbin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin

function usage() {
  # Usage
  if [[ -n "${@}" ]] ; then
    echo "ERROR: ${@}"
  fi

  cat <<EOF

USAGE: ${0##*/} [ -h | -m | -c ]

-h         This useful output

-m         Just back up the media, not 
           the plex configuration

-c         Just back up the configuration, not
           the media

NOTE: 
  - Having no arguments is the same as both -m and -c
  - Only one argument is taken

EOF
}


function get_new_files() {
  # Checks if there are any new files that need backing up and echos a list of them 
  # with quotes so filenames with spaces and other characters can still be included
  IFS=$'\n'
  for i in $(find . -type f -newer $target_dir/$latest_bu -not -iname "*.rpm"); do 
    echo -n "\"$i\" "
  done
  unset IFS
}


function media_backup() {
  # Media backup Function
  cd $source_dir
  filesString="$(get_new_files)"
  if [[ -z $filesString ]]; then 
    echo "No new media files to back up" >> $log_file
    exit 1
  else
    echo "$the_date:  Starting media file backup" >> $log_file
    echo "tar czf $archive_file $filesString" | /bin/sh
    if [[ $? -eq 0 ]]; then
      echo "successfully archived the following files into $archive_file:" >> $log_file
      printf "$(echo "$filesString" | sed 's/^"//g;s/" "/\\n/g;s/"//g')\n\n" >> $log_file
    else
      echo -e "Media file backup failed\n" >> $log_file
    fi
  fi
}


function config_backup() {
  # Plex Configuration Backup function
  cd $pconf_src_dir
  echo "$the_date:  Starting Plex Media Server configuration backup" >> $log_file
  echo "tar czf $pconf_tgt_dir/$pconf_archive_file Plex\ Media\ Server/" | /bin/sh
  if [[ $? -eq 0 ]]; then
    echo -e "successfully archived Plex Media Server configurations into $pconf_tgt_dir/$pconf_archive_file\n" >> $log_file
  else
    echo -e "Plex Media Server configuration backup failed\n" >> $log_file
  fi
}


function main() {
  # Main Function

  local the_date=$(date +%Y%m%d-%H%M)

  ### Customize Here ###
  
  local source_dir="/home/plex"
  local target_dir="/mnt/backups"
  local archive_file="$target_dir/media_backups_plex01_$the_date.tgz"
  local pconf_src_dir="/var/lib/plexmediaserver/Library/Application*Support/"
  local pconf_tgt_dir="/mnt/backups/configs/plex"
  local pconf_archive_file="Plex_Media_Server_configs_$the_date.tgz"
  local log_file="/mnt/backups/media_bu.log"
  
  ### End Customization ###
  
  # creates log file if it does not exist already
  if [[ ! -f $log_file ]] ; then touch $log_file; fi
  
  # Get's the last archive file for time comparison in find command
  local latest_bu="$(ls -1t $target_dir | grep media_backups_plex01 | head -1)"

    if [[ -z "${@}" ]]; then
      media_backup
      config_backup
    else
      case "${@}" in
        -h) usage ;;
        -m) media_backup ;;
        -c) config_backup;;
      esac
    fi

}

main ${1}
