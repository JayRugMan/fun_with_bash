#!/bin/zsh


function get_date_time() {
  local video="${1}"; shift
  local date_time=$(ffprobe -hide_banner ${video} 2>&1 | awk -F'( |-){1,}' '/ creation_time / {print $4 $5 $6; exit}')
  local vid_time=${date_time##*T}
  vid_time=${vid_time%.*} 
  vid_time=$(echo ${vid_time} | sed 's/:/./g')
}


for vid in $(ls -1 *.MP4); do
  echo ${vid}
done