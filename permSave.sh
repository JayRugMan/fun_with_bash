#!/bin/bash
# This script records permissions for all of the files and
# directories down the directory tree from the location in
# which the script is issued into a file that simply needs
# to be sourced to restore permissions.
# Limitation:
#   - It currently doesn't handle sticky-bits, only r, w,
#     and e.


# Sets home directory from where the directory tree starts, To abstract absolute path
homedir="$PWD"
### MODIFY TARGET DIRECTORY FOR PERMISSION RESTORE FILE ###
sourcepermFile="$HOME/${homedir##*/}_$(date +%y%m%d_%H%M).file" # file for sourcing

# Finds all objects and checks the stats, echoing the permission number bits
# in context of the chmod command and directs the constructed chmod command
# to the sourcepermFile to be sourced to restore permissions
find . -exec stat -c"chmod %a \"$homedir/%n\" 2>/dev/null" {} + | sed 's/\/\.\//\//g; s/\/\."/"/g' > ${sourcepermFile}

echo -e "\nsource $sourcepermFile as root to restore mod bits for files in $homedir\n"
