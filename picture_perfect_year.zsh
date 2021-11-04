#!/usr/bin/zsh
# Created by Jason Hardman 2021-11-03
# Please note this is a zsh script, not my usualy bash, so
# - arrays work differently
# - splitting a command into to or more lines does not require a backslash if piped
# - I can iterate over a referenced array's key and value in a single, simple for-loop


function get_pic_info() {
  # loads PICTURES array with picture name and date as key and value
  # the reason I don't just pull the creation date from identify on all images
  # is because with jpg files, the taken date in the exif data is older and
  # likely more accurate. However, if the exif data is not available on a jpg,
  # then identify is tried. If both fail, then "unknown_date" is assigned
  # This function can also handle video files.
  IFS=$'\n'
  for the_pic in $(ls | grep -i "jpg\|jpeg\|png\|gif\|mp3\|mp4\|wav\|mov"); do
    pic_type="${the_pic##*.}"
    if [[ ${pic_type:l} == "jpg" ]] || [[ ${pic_type:l} == "jpeg" ]]; then
      the_y="$(exif -t DateTimeOriginal --machine-readable "$the_pic" 2>/dev/null |
               awk -F':' '{print $1}'
               )"
    fi
    if [[ ${pic_type:l} == "mp3" ]] || [[ ${pic_type:l} == "mp4" ]] || [[ ${pic_type:l} == "wav" ]] || [[ ${pic_type:l} == "mov" ]] ; then
      the_y="$(ffprobe -hide_banner "$the_pic" 2>&1 |
               awk -F'( |-){1,}' '/creation_time/ || / date / {print $4; exit}'
              )"
    fi
    if [[ ${pic_type:l} == "png" ]] || [[ ${pic_type:l} == "gif" ]] || [[ -z "$the_y" ]]; then
      the_y="$(identify -verbose "$the_pic" 2>/dev/null |
               awk -F'( |-){1,}' '/date:create:/ {print $3}'
              )"
    fi
    if [[ -z "$the_y" ]]; then
      the_y="unknown_date"
    fi
    PICTURES[$the_pic]="$the_y"
    unset the_y
  done
  unset IFS
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
    echo "mv -v \"$the_picture\" \"$the_year\"" | /usr/bin/zsh
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
