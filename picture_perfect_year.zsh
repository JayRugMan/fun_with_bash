#!/usr/bin/zsh
# Created by Jason Hardman 2021-11-03
# Please note this is a zsh script, not my usualy bash, so
# - arrays work differently
# - splitting a command into to or more lines does not require a backslash if piped
# - I can iterate over a referenced array's key and value in a single, simple for-loop


function get_pic_info() {
  # loads PICTURES array with picture name and date as key and value
  for the_pic in $(ls | grep -i "jpg\|png"); do
    pic_type=${the_pic##*.}
    if [[ ${pic_type:l} == "jpg" ]] || [[ ${pic_type:l} == "jpeg" ]]; then
      the_y=$(exif -t DateTimeOriginal --machine-readable $the_pic |
               awk -F':' '{print $1}'
              )
      PICTURES[$the_pic]="$the_y"
    elif [[ ${pic_type:l} == "png" ]]; then
      the_y=$(identify -verbose $the_pic |
               awk -F'( |-){1,}' '/date:create:/ {print $3}'
              )
      PICTURES[$the_pic]="$the_y"
    fi
  done
}


function get_year_list() {
  # Gets a list of the years for creating the directories
  for i in ${PICTURES[@]}; do
    if [[ ! ${YEARS[@]} =~ $i ]]; then
      YEARS+=($i)
    fi
  done
}


function make_dir() {
  # If the direcotry of the year does not exist, it's created
  for the_yr in ${YEARS[@]}; do
    if [[ ! -d "$the_yr" ]]; then
      mkdir $the_yr
    fi
  done
}


function move_them_pics() {
  # Pictures are moved to the corresponding year directory
  for the_picture the_year in ${(@kv)PICTURES}; do
    mv -v "$the_picture" "$the_year/"
  done
}


function main() {
  # The main even
  typeset -A PICTURES
  typeset -a YEARS
  get_pic_info
  get_year_list
  make_dir
  move_them_pics
}


main
