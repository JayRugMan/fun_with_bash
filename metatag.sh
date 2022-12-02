#!/bin/bash
# Gets info like title, album, etc.. from user to tag video/audio file with ffmpeg


function usage() {
  # The Usage
  cat <<EOF
 USAGE:

 -p, --probe        get the goods already there

 -t, --tag          enter tags

 *                  this helpful output

EOF
}


function probe_it() {
  # Probes data
  local the_file="${@}"
  ffprobe -hide_banner "${the_file}"
}


function just_ask() {
  # Gets user input based on what's needed
  local the_label=${1}
  local the_answer=""
  read -p "${the_label} (Leave blank to skip): " -e the_answer
  echo "${the_answer}"
}


function tag_it() {
  # Tags with data
  local the_tag_labels=("title" "album" "album_artist" "artist" "comment" "date" "track" "disc" "copyright")
  for lab in ${the_tag_labels[@]}; do
    local the_tag="$(just_ask "${lab}")"
    if [[ -n "${the_tag}" ]] ; then
      FINAL_COMMAND="${FINAL_COMMAND} -metadata ${lab}=\"${the_tag}\""
    fi
  done
}


function run_final_command() {
  # shows and runs final command

  local i_file="${1}"; shift
  local o_file="${1}"
  local git_the_go=""

  echo -e "\n The Final Command:\n"
  echo -e "${FINAL_COMMAND}\n"
  read -p "Run? (y/n): " give_the_go
  if [[ "${give_the_go}" == "y" ]]; then
    echo "${FINAL_COMMAND}" | sh
    echo -e "\n\n new file:\n${o_file}"
    echo -e "\n\n command to remove old file:\nrm -f \"${i_file}\""
  else
    echo "Nothing Done"
  fi
}


function main() {
  # The Main Event

  local arg="${@}"

  case ${arg} in
    "-p" | "--probe")
      local input_file="$(just_ask "Input File")"
      probe_it "${input_file}"
      ;;
    "-t" | "--tag")
      local input_file="$(just_ask "Input File")"
      local output_file="$(just_ask "Output File")"
      FINAL_COMMAND="ffmpeg -hide_banner -i \"${input_file}\" -c copy -map_metadata 0"
      tag_it
      FINAL_COMMAND="${FINAL_COMMAND} \"${output_file}\""
      run_final_command "${input_file}" "${output_file}"
      ;;
    *)
      usage
      ;;
  esac
}

main "${@}"
