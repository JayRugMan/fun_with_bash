#!/usr/bin/zsh
# Created by Jason Hardman 2021-11-03
# Please note this is a zsh script, not my usualy bash, so
# - arrays work differently
# - splitting a command into two or more lines does not require a backslash if piped
# - I can iterate over a referenced array's key and value in a single, simple for-loop


function get_pic_info() {
  # loads PICTURES array with picture name and date as key and value
  # the reason I don't just pull the creation date from identify on all images
  # is because with jpg files, the taken date in the exif data is older and
  # likely more accurate. However, if the exif data is not available on a jpg,
  # then identify is tried. If both fail, then "unknown_date" is assigned
  # This function can also handle video files.
  IFS=$'\n'

  ## Add file-types below
  pic_ext_array_jpg=( jpg jpeg )
  pic_ext_array_other=( png gif bmp )
  vid_ext_array=( mp3 mp4 wav mov mpg flv avi )
  ##

  # String made from arrays for grep search
  grep_search_filter="$(echo "${pic_ext_array_jpg[@]} ${pic_ext_array_other[@]} ${vid_ext_array[@]}" | sed 's/ /\\|/g')"
  no_exif=false

  for the_file in $(ls | grep -i "${grep_search_filter}"); do
    file_type="${the_file##*.}"

    echo -ne "${the_file}: Working..."

    if [[ "${pic_ext_array_jpg[@]}" =~ ${file_type:l} ]]; then
      the_y="$(exif -t DateTimeOriginal --machine-readable "$the_file" 2>/dev/null |
               awk -F':' '{print $1}'
               )"
      if [[ -z "$the_y" ]]; then
        no_exif=true
      fi
    fi

    if [[ "${pic_ext_array_other[@]}" =~ ${file_type:l} ]] || ${no_exif} ; then
      the_y="$(identify -verbose "$the_file" 2>/dev/null |
               awk -F'( |-){1,}' '/date:create:/ {print $3}'
              )"
    fi

    if [[ "${vid_ext_array[@]}" =~ "${file_type:l}" ]]; then
      the_y="$(ffprobe -hide_banner "$the_file" 2>&1 |
               awk -F'( |-){1,}' '/creation_time/ || / date / {print $4; exit}'
              )"
    fi

    if [[ -z "$the_y" ]]; then
      the_y="unknown_date"
    fi

    PICTURES[$the_file]="$the_y"
    unset the_y

    echo -e "/b/b/b/b/b/b/b/b/bComplete   "

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
  echo "Getting picture info"; get_pic_info
  echo "Getting list of years";  get_year_list
  echo "Making directories if needed"; make_dir
  echo "Moving Pictures"; move_them_pics
}


main
