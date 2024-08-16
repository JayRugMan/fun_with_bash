#!/bin/zsh


function get_date_time() {
  # Takes the filename and returns the date_time in filename format

  local video="${1}"; shift
  
  if [[ -f "${video}" ]]; then

    local date_time=$(ffprobe -hide_banner "${video}" 2>&1 | awk -F'( |-){1,}' '/ creation_time / {print $4 $5 $6; exit}')  # IE 20240121T18:49:38.000000Z
    local vid_date=${date_time%T*}  # IE 20240121
    local vid_time=${date_time##*T}  # IE 18:49:38.000000Z
    vid_time=${vid_time%.*}  # IE 18:49:38
    vid_time=$(echo ${vid_time} | sed 's/://g')  # IE 184938
    date_time="${vid_date}_${vid_time}"  # IE 20240121_184938

    echo "MEVO_${date_time}.MP4"
    return 0

  else
    return 1
  fi
}



function main() {
  # The main event

  IFS=$'\n'
  for vid in $(ls -1 *.MP4); do

    if file_name=$(get_date_time "${vid}"); then
      echo "Renaming ${vid} to ${file_name}"
      echo "mv -v \"${vid}\" \"${file_name}\"" | sh
    else
      echo "File ${vid} not found."
    fi

  done
  unset IFS

}

main
