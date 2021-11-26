#!/usr/bin/env zsh
# Created by Jason Hardman
# 2021-11-21

## THESE COMMANDS NEED BE BECOME A SCRIPT

## testMessage="This is a test Message"

function get_message() {
  # gets the message from the optarg
  optarg="${@}"
  if [[ -f "$optarg" ]]; then
    THE_MESSAGE="$(cat "$optarg")"
  else
    THE_MESSAGE="$optarg"
  fi
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
    usage "No book Provided"
    exit 1
  elif [[ "$has_message" -ne 1 ]]; then
    usage "No message Provided"
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
        echo "$code_bits $char" >&2
        final_string+="${code_bits} "
        unset code_bits
        break
      elif [[ ${line} == "${book_lines}" ]]; then
        echo "$line $char" >&2
        line=1
      else
        echo "nothing: $line" >&2
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
