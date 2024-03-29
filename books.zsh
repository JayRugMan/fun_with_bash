#!/usr/bin/env zsh
# Created By Jason Hardman on 2021-11-19/20
# Book code decypherer


function usage() {
  # Prints usage
  if [ "$@" ] ; then
    echo "ERROR: ${@}"
  fi
  cat <<EOF

Usage:

I hope you're good with zsh code so you can pick apart the script for usage ;D

EOF
}


function get_code() {
  # gets the code from the optarg
  optarg="${@}"
  if [[ -f "$optarg" ]]; then
    THE_CODE="$(cat $optarg)"
  else
    THE_CODE="$optarg"
  fi
}


function getOptions() {
  local OPTIND OPTION b c h
  while getopts "b:c:h" OPTION; do
    case "$OPTION" in
      'b') # book
        THE_BOOK="$(cat ${OPTARG:-/dev/stdin})"
        has_book=1
        ;;
      'c') # code file or string
        get_code "$OPTARG"
        has_code=1
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
  if [[ "$has_book" -ne 1 ]]; then
    usage "I have nothing to read\!"
    exit 1
  elif [[ "$has_code" -ne 1 ]]; then
    usage "Silence is compliance\!"
    exit 1
  fi
}


function this_seds_it_all() {
  # Filters for known special character charset with sed
  sed "s/+/ /g;
     s/XSPp/./g;
     s/XSPc/,/g;
     s/XSPa/'/g;
     s/XSPq/?/g;
     s/XSPl/+/g;
     s/XSPd/-/g;
     s/XSPe/=/g;
     s/XSPo/:/g;
     s/XSP1/\!/g;
     s/XSP2/@/g;
     s/XSP3/#/g;
     s/XSP4/$/g;
     s/XSP5/%/g;
     s/XSP6/^/g;
     s/XSP7/\&/g;
     s/XSP8/*/g;"
}


function decypher() {
  # Magic happens here
  message=""
  line_counter=1
  while [[ ! -z "$THE_CODE" ]]; do  # THE_CODE deminished until it is unset as the loop progresses
    echo "${THE_BOOK}" | while read str_line; do
      coded_line="${THE_CODE%% *}"  # gets the first number in the remaining sequence
      if [[ "$coded_line" == "$line_counter" ]]; then
        char_num="${${THE_CODE#* }%% *}"  # gets the "first" of all but the first number in the remaining sequence - so essentually the second
        
        # the parameter expansion utilized breaks down with only two
        # "elements", so this if statement changes the logic depending
        # on the number of "elements" left, thus avoiding an endless loop
        if [[ $(echo "$THE_CODE" | awk '{print NF}') -gt 2 ]]; then
          THE_CODE="${${THE_CODE#* }#* }"  # removes the first two numbers
        else
          unset THE_CODE
        fi
        
        message+="${str_line[${char_num}]}"
        break
      fi
      ((line_counter++))
    done
    line_counter=1
  done

  echo -e "\tMESSAGE:\n${message}" | this_seds_it_all
}


function main() {
  # MAIN FUNCTION
  declare THE_BOOK
  declare THE_CODE
  getOptions "${@}"
  decypher
}


main "${@}"
