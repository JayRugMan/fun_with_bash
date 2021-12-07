#!/usr/bin/env zsh
# Created by Jason Hardman
# 2021-11-21
# This script encrypts - takes a message and book file, returns number pairs

## testMessage="This is a test Message"


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

-m "string" | file.txt       This designates the message you want encoded as
                             number pairs. It can either be a quoted string or
                             a file with a string. See the section below on
                             special characters.

*                            Prints this helpful output

Special Characters:          Only the following special characters will work:
                                     . , ' ? + - = : ! @ # $ % ^ & * /
                             Note: Because of how some of these are interpreted
                             by the shell it would be wise to create a message
                             file and reference that with the -m option

EOF
}


function get_message() {
  # gets the message from the optarg
  optarg="${@}"
  if [[ -f "$optarg" ]]; then
    THE_MESSAGE="$(cat "$optarg")"
  else
    THE_MESSAGE="$optarg"
  fi
}


function filter_special_char() {
  # turns special characters into text strings for encoding
  case "${@}" in
    '.')
      special_chars="XSPp";;
    ',')
      special_chars="XSPc";;
    "'")
      special_chars="XSPa";;
    '?')
      special_chars="XSPq";;
    '+')
      special_chars="XSPl";;
    '-')
      special_chars="XSPd";;
    '=')
      special_chars="XSPe";;
    ':')
      special_chars="XSPo";;
    '!')
      special_chars="XSP1";;
    '@')
      special_chars="XSP2";;
    '#')
      special_chars="XSP3";;
    '$')
      special_chars="XSP4";;
    '%')
      special_chars="XSP5";;
    '^')
      special_chars="XSP6";;
    '&')
      special_chars="XSP7";;
    '*')
      special_chars="XSP8";;
    ' ')
      special_chars="+";;
    *)
      special_chars="${@}";;
  esac
  echo "${special_chars}"
}


function swap_specials() {
  # Changes out special characters in message to comply with base62 available characters
  new_message=""
  num_mess_char_offset="$((${#THE_MESSAGE}-1))"
  for i in $(seq 0 ${num_mess_char_offset}); do
    new_char="$(filter_special_char "${THE_MESSAGE:${i}:1}")"
    new_message+="${new_char}"
  done
  THE_MESSAGE="${new_message}"
}


function getOptions() {
  local OPTIND OPTION b m h
  while getopts "b:m:h" OPTION; do
    case "$OPTION" in
      'b') # book
        THE_BOOK="$(cat ${OPTARG:-/dev/stdin})"
        has_book=1
        ;;
      'm') # message file or string
        get_message "$OPTARG"
        swap_specials
        has_message=1
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
    usage "I need something to read\!"
    exit 1
  elif [[ "$has_message" -ne 1 ]]; then
    usage "Silence is compliance\!"
    exit 1
  fi
}


function cypher() {
  # Magic happens here
  book_lines=$(echo "${THE_BOOK}" | wc -l)
  declare -a code_lines
  declare final_string

  for i in $(seq 1 ${#THE_MESSAGE}); do
    code_lines+=( $(( $RANDOM % $((${book_lines})) )) )
  done

  for i in $(seq 1 ${#code_lines}); do
    # because messages likely have spaces and
    # base64 does not, I turn them into "+"
    if [[ "${THE_MESSAGE[$i]}" == " " ]]; then
      char='+'
    else
      char="${THE_MESSAGE[$i]}"
    fi
    # this gets the line number, which will incement if
    # the specified character isn't found on that line
    line="${code_lines[$i]}"
    # while loop exits if character is found on
    # the specifed line, or the line increments
    while true; do
      code_bits="$(echo "${THE_BOOK}" | awk -v ln_nm="${line}" -v ltr="${char}" '
                    NR==ln_nm {
                        for(i=1; i<=length($0); i++)
                        if(substr($0,i,1)==ltr)
                        print NR " " i
                      }
                    ' | tail -1
                  )"
      if [[ ! -z "$code_bits" ]] && [[ "$code_bits" != 0 ]]; then
        final_string+="${code_bits} "
        unset code_bits
        break
      elif [[ ${line} == "${book_lines}" ]]; then
        line=1
      else
        ((line++))
      fi
    done
  done
  echo "$final_string"
}


function main() {
  # MAIN FUNCTION
  declare THE_BOOK
  declare THE_MESSAGE
  declare -a THE_KEYS
  getOptions "${@}"
  cypher  # prints out code as it's configured
}


main "${@}"
