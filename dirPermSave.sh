#!/bin/bash

# Created by Jason Hardman
# Date 20210818
# creates a file that can be sourced which records ownership and permissions
# of a file structure in Linux per the deptch specified
# Unlike earlier versions, this script does work with stick or Special bits


function usage() {
  # Prints usage
  if [[ ! -z ${1} ]]; then
    echo "ERROR - ${@}"
  fi
  cat <<EOF

Usage:

  You must specify a target directory and 
  how deep into it you would like to go.

  $0 <integer for directory structure depth> <base directory>

EOF
}


## Parameters
if ! [[ ${1} =~ ^[0-9]+$ ]]; then
  usage "The first parameter must be an integer"
  exit 1
fi

dir_depth=${1}  # first parameter, which should be an integer
shift

if ! [[ -d "${@}" ]]; then
  usage "the directory ${@} is not found"
  exit 1
fi

base_dir="${@}"  # remaining parameters, which should be a directory
the_date_time="$(date +%Y%m%d-%H%M%S)"  # date/time for file name YYYYMMDD-HHMMSS
the_output_file="/tmp/dir_permissions_backup_${the_date_time}.txt"  # output file
##


  # Creates file by loading with instructive header
if cd ${base_dir}; then
  echo "## source this file in \"${base_dir}\" to recover permissions and ownership" > ${the_output_file}
    # finds directories in the base directory, skipping .snapshot directories, and loads output file with current permissions
  find "${base_dir}" -maxdepth $dir_depth -mindepth 1 -name .snapshot -prune -o -type d -exec stat -c"chown %U:%G %n" {} \; -exec stat -c"chmod %a %n" {} \; >> ${the_output_file}
    # sed to add 00 before permissions without special permissions bit so any special bit can be removed when restored from backup
  sed -i 's/^chmod [0-7][0-7][0-7] /00&/g; s/^00chmod /chmod 00/g' ${the_output_file}
  echo -e "-- Rollback source file is ${the_output_file}\n--- (Source in directory specified on the file's first line)"
else
  usage "Could not change to ${base_dir}"
fi
