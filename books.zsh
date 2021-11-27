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

-b <book> | -                This designates the file or input that
                             acts as the "book" in the book code.
                             It can be piped to standard in, which
                             requires "-b -" or be specified file

-c "string" | file.txt       This designates the encoded string of
                             numbers, formatted in pairs where the
                             first of each pair is the line and the
                             second it the character. All numbers
                             should be separated by a space.

*                            Prints this helpful output

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
    usage "No book Provided"
    exit 1
  elif [[ "$has_code" -ne 1 ]]; then
    usage "No code Provided"
    exit 1
  fi
}


function decypher() {
  # Magic happens here
  message=""
  line_count=1
  while [[ ! -z "$THE_CODE" ]]; do
    echo "${THE_BOOK}" | while read str_line; do
      coded_line="${THE_CODE%% *}"
      if [[ "$coded_line" == "$line_count" ]]; then
        char_num="${${THE_CODE#* }%% *}"
        THE_CODE="${${THE_CODE#* }#* }"  # removes the first two coded numbers
        message+="${str_line[${char_num}]}"
      fi
      ((line_count++))
    done
    line_count=1
  done

  echo -e "\tMESSAGE:\n${message}"
}


function main() {
  # MAIN FUNCTION
  declare THE_BOOK
  declare THE_CODE
  getOptions "${@}"
  decypher
}


main "${@}"
