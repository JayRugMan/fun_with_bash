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


function get_keys() {
  # gets the keys for an ordered array because order
  # matters and associative arrays are unordered
  code_str="${@}"
  key_count=${#THE_CODE}
  for i in $(seq 1 ${key_count}); do
    # appends the first value of the string (the key) to the keys array
    THE_KEYS+=(${code_str%% *})
    # removes the first two values (first key/value pair) of the string
    code_str="${code_str#* }" ; code_str="${code_str#* }"
  done
}


function get_code() {
  # gets the code from the optarg
  optarg="${@}"
  if [[ -f "$optarg" ]]; then
    code_string=( $(cat "$optarg") )
  else
    code_string=( $(echo $optarg) )
  fi
  THE_CODE=( $(echo $code_string) )
  get_keys "${code_string}"
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
  for key in ${THE_KEYS[@]}; do
    echo "${THE_BOOK}" | while read str_line; do
      if [[ "$key" == "$line_count" ]]; then
        char_num="${THE_CODE[$key]}"
        echo $char_num >&2
        #((THE_CODE[$key]--))
        #JHmessage+="${str_line:${THE_CODE[$key]}:1}"
        message+="${str_line[${char_num}]}"
      fi
      ((line_count++))
    done
    echo "${message}" >&2
    line_count=1
  done

  echo -e "\tMESSAGE:\n${message}"
}


function main() {
  # MAIN FUNCTION
  echo "DECODE DEBUG" >&2
  declare THE_BOOK
  declare -A THE_CODE
  declare -a THE_KEYS
  getOptions "${@}"
  decypher
}


main "${@}"
