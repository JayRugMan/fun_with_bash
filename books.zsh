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


function getOptions() {
  local OPTIND OPTION b c h
  while getopts "b:c:h" OPTION; do
    case "$OPTION" in
      'b') # book
        THE_BOOK="$(cat ${OPTARG:-/dev/stdin})"
        has_book=1
        ;;
      'c') # code file or string
        if [[ -f "$OPTARG" ]]; then
          THE_CODE=( $(cat "$OPTARG") )
        else
          THE_CODE=( $(echo $OPTARG) )
        fi
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


function main() {
  ## Args
  declare THE_BOOK; declare -A THE_CODE; getOptions "${@}"
  decyphered=""
  line_count=1

  for line_num letter_num in ${(kv)THE_CODE[@]}; do
    echo "${THE_BOOK}" | while read str_line; do
      if [[ "$line_num" == "$line_count" ]]; then
        ((letter_num--))
        decyphered="${str_line:${letter_num}:1}${decyphered}"
      fi
      ((line_count++))
    done
    line_count=1
  done

  echo -e "  MESSAGE:\n${decyphered}"
}


main "${@}"
