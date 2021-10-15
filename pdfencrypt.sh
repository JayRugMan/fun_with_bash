#!/bin/bash
# This script encrypts PDF files using Yad to get 
# the desired pw in masked text, then passes that
# to qpdf for 256-bit encryption


function usage() {
  # Prints Usage
  cat <<EOF

ERROR: ${@}

 Usage:

 ${0##*/} <Input PDF file> <Output file>

EOF
}


## Error Checks
if [[ -z "$1" ]] || [[ -z "$2" ]]; then
  usage "Argument(s) Missing"
  exit 1
elif [[ ! -f "$1" ]]; then
  usage "File $1 Not Found"
  exit 1
elif [[ ! "$(file ${1})" =~ "PDF document" ]]; then
  usage "$1 Is Not a PDF"
  exit 1
elif [[ -f "$2" ]]; then
  read -p "Output File ${2} Exists! Overwrite (YES/no)? " -e overwrite
  if [[ ! "$overwrite" == "YES" ]]; then
    usage "Output File Exists and Overwrite Not Confirmed"
    exit 1
  fi
fi

inputFile="${1}"
outputFile="${2}"

rpw=$(yad --on-top --width=400 --entry --entry --title="Enter Reader password for PDF encryption" --hide-text)
opw=$(yad --on-top --width=400 --entry --entry --title="Enter Owner password for PDF encryption" --hide-text)

echo "qpdf --encrypt '$rpw' '$opw' 256 -- $inputFile $outputFile" | sh
