#!/usr/bin/env zsh
# Created by Jason Hardman
# 2021-11-21

## THESE COMMANDS NEED BE BECOME A SCRIPT

testMessage="This is a test Message"
num_lines=$(base64 recordings.png | wc -l)
declare -a book_lines
echo ${book_lines[@]}
for i in $(seq 1 ${#testMessage}); do book_lines+=( $(( $RANDOM % ${num_lines} )) ); done
for i in ${book_lines[@]}; do base64 recordings.png | awk -v ln_nm="$i" 'NR==ln_nm' ; done
echo "${testMessage}"
base64 recordings.png | awk -v ln_nm="47" -v ltr="z" 'NR==ln_nm {for(i=1; i<=length($0); i++) if(substr($0,i,1)==ltr) print NR " " i}'
