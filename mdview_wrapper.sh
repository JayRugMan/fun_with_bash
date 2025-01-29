#!/bin/bash
# This scripts is a wrapper for opening mdview and YAD to select the file


function get_file() {
  # gets the file
  local md_file=$(yad --file --title="Select a Mark Down (.md) file")
  echo "${md_file}"
}


function check_file() {
  # Makes sure the file is a markdown file
  local the_file="${@}"

  if [[ "$(file "${the_file}")" =~ " ASCII text" ]] && [[ "${the_file##*.}" == 'md' ]]; then
    return 0
  else
    return 1
  fi
}


function main() {
  # The Main Event
  while true; do
    file="$(get_file)"
    if check_file "${file}" && [[ -n "${file}" ]]; then
      break
    fi
  done
  mdview "${file}"
}


main