#!/bin/bash
# Created by Jason Hardman on 20211021

# Configurable arguments at the start of main function


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
  if [[ "$has_artist" -ne 1 ]]; then
    usage "No Artist Provided"
    exit 1
  elif [[ "$has_song" -ne 1 ]]; then
    usage "No Song Provided"
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
  /usr/bin/ffmpeg -i "$m4a_file" \
                  -map_metadata 0 \
                  -metadata title="$THE_SONG" \
                  -metadata artist="$THE_ARTIST" \
                  -metadata album="$the_album" \
                  -metadata track=$the_track \
                  -metadata disc=1 \
                  -metadata album_artist="$THE_ALBUM_ARTIST" \
                  "$mp3_file" >/dev/null 2>&1
  echo " - Converted to \"$mp3_file\""
}


function archive_m4a() {
  # Move the downloaded m4a file to archive m4a_dir
  the_file="${1}"
  the_dir="${2}"
  mv -v "$the_file" "$the_dir"
  echo " - Archived $the_file to $the_dir"
}


function main() {
  ## ARGS
  THE_ARTIST=""; THE_SONG=""; getOptions "${@}"
  THE_ALBUM_ARTIST="Various Artists"
  target_dir="/home/jason/music/Mixed/ElectroString/"
  m4a_dir="/home/jason/music/m4aFiles/"
  album="Electrostring"
  next_track="$(ls -1 $target_dir | awk 'END{printf "%02i\n", ($1+1)}')"
  url="$(/home/jason/bin/youtubeSearch.sh "${THE_ARTIST} ${THE_SONG}")"
  ##

  # Go to the target directory, download the video from YouTube, convert it to
  # MP3 format with metadata, and archive the M4A file
  cd "$target_dir"
  echo " - Changed to $target_dir"
  echo " - \"${THE_SONG}\" by ${THE_ARTIST} found at ${url} "
  echo -n " - Download started..."

  /usr/local/bin/youtube-dl -f 'bestaudio[ext=m4a]' \
                            --restrict-filenames "$url" \
                            >/dev/null 2>&1
  if [[ $? -eq 0 ]]; then
    echo -e "\b\b\b\b\b\b\b\b\b\bcomplete  "
    new_file="$(ls | grep -E 'm4a$')"
    to_mp3 "$next_track" "$new_file" "$album"
    archive_m4a "$new_file" "$m4a_dir"
  else
    echo -e "\b\b\b\b\b\b\b\b\b\bfailed    "
  fi
}


main "${@}"
