#!/bin/bash
# This script records permissions for all of the files and
# directories down the directory tree from the location in
# which the script is issued into a file that simply needs
# to be sourced to restore permissions.
# Limitation:
#   - files or directories with spaces or special characters
#     xnix systems recommend against, IE SPACE, <, >, |, :,
#     (, ), &, ;, *, ? are not handled properly- errors will
#     occur when sourcing the restore file.
#   - It currently doesn't handle sticky-bits, only r, w,
#     and e.
# To check whether any filenames have characters that break this script,
# issue the following first:
# ls -R | grep -E "./[ <>|\:()$;?*]{1,}./"
 
function permfilter(){
  ## This module takes a single permissions trio, ID r-x, or
  ## rwx, etc. and prints the corresponding chmod numeric
  ## mode number, 0-7
  permissions="${1}"
  loadModBit=0
   
  for i in `seq 0 2`; do
    case ${permissions:$i:1} in
      r)
         loadModBit=$(($loadModBit+4));;
      w)
         loadModBit=$(($loadModBit+2));;
      x)
         loadModBit=$(($loadModBit+1));;
    esac
  done
     
    echo "${loadModBit}"
}
# Sets home directory from where the directory tree starts, To abstract absolute path
homedir="$PWD"
# Creates a directory tree with sub-directory titles and it's contents' permissions
DirTreePerms="$(for i in `find . -type d`; do echo $i; ls -l $i | grep -v total; done)"
sourcepermFile="/home/jhardman/dokuwikiPerm_${homedir##*/}_$(date +%y%m%d_%H%M).file" # file for sourcing
#JH sourcepermFile=/home/jhardman/testPerm.file # file for sourcing
echo "$DirTreePerms" | awk '{print $1" "$9}' | \
while read perms object; do
  if [[ -z $object ]]; then # this basically means the line printed is the subdirectory itself - basically,
                            # the object is in the perms argument
    subdir="$(echo "$homedir/${perms}" | sed 's/\.\///g')" # appends the subdirectory to the base directory
    ##JH echo $subdir
    ##JH echo "cd $subdir" | sh
    continue
  else
    echo "chmod $(permfilter ${perms:1:3})$(permfilter ${perms:4:3})$(permfilter ${perms:7:3}) ${subdir}/${object} > /dev/null 2>&1" >> ${sourcepermFile}
  fi
done
echo -e "\nsource $sourcepermFile as root to restore mod bits for files in $homedir\n"
