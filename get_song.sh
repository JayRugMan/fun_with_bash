#!/bin/bash


function usage() {
  # Prints usage
  if [ "$@" ] ; then
    echo "ERROR: ${@}"
  fi
  cat <<EOF

Usage:

-a "<artist>"       Artist (required)

-s "<song>"         Song (required)

*                   Prints this helpful output

EOF
}


function getOptions() {
  local OPTIND OPTION a s h
  while getopts "a:s:h" OPTION; do
    case "$OPTION" in
      'a') # Artist String
        THE_ARTIST="$OPTARG"
        has_artist=1
        ;;
      's') # Song string
        THE_SONG="$OPTARG"
        has_song=1
        ;;
      'h')
        usage
        exit 1
        ;;
      ?)
        usage
        exit 1
        ;;
    esac
  done
  shift "$((OPTIND -1))"
  if [[ ${has_song} -ne 1 ]]; then
    usage "No song provided"
    exit 1
  elif [[ ${has_artist} -ne 1 ]]; then
    usage "No artist provided"
    exit 1
  fi
}


function to_mp3() {
  # Changes name to "xx - Artist - Song.mp3"
  # Adds album set as third arg
  the_track="${1}"
  m4a_file="${2}"
  the_album="${3}"
  mp3_file="${the_track} - ${THE_ARTIST} - ${THE_SONG}.mp3"
  /usr/bin/ffmpeg -i "$m4a_file" -map_metadata 0 -metadata album="$the_album" "$mp3_file"
}


function archive_m4a() {
  # Move the downloaded m4a file to archive m4a_dir
  the_file="${1}"
  the_dir="${2}"
  mv -v $the_file $the_dir
}


function main() {
  ## ARGS
  THE_ARTIST=""; THE_SONG=""; getOptions ${@}
  target_dir="/home/jason/music/Mixed/ElectroString/"
  m4a_dir="/home/jason/music/m4aFiles/"
  album="Electrostring"
  next_track="$(ls -1 $target_dir | awk 'END{printf "%02i\n", ($1+1)}')"
  url="$(/home/jason/bin/youtubeSnD.sh "${THE_ARTIST} ${THE_SONG}")"
  ##

  cd "$target_dir"
  /usr/local/bin/youtube-dl -f 'bestaudio[ext=m4a]' --restrict-filenames "$url"
  new_file="$(ls -1tr | tail -1)"
  to_mp3 "$next_track" "$new_file" "$album"
  archive_m4a "$new_file" "$m4a_dir"
}


main ${@}
