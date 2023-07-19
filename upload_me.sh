#!/bin/bash
# Created by Jason Hardman for uploading files to linux servers


function usage() {
  # The Usage
  if [[ -n "${@}" ]]; then
    echo -e "ERROR: ${@}\n"
  fi

  cat <<EOF
USAGE: ${0##*/} [-i | -u <user> -s <target server> [-d <target directory>] -f <the file> | *] [-F]

 -i                     Interactive mode

 -u                     The user with which the connection is made This is 
                        optional, current user is assumed if not provided.

 -s                     The remote server hostname (domain is added)

 -d                     Which directory is being targeted? This is optional,
                        /home/user is assumed if not provided.

 -f                     Which file is being uploaded?

 -F                     Force, or don't confirm before sending (useful for scripting)

 *                      Anything else gets you this lovely usage output.


NOTE:

The DOMAIN can be left off, hard-coded (check parameter in the main function), or added when prompted

EOF

  exit 1
}


function show_prompt() {
  # The prompt

  if [[ "${1}" == "-d" ]]; then
    local default="${2}"; shift 2
  fi

  local the_prompt="${@}"

  while true; do
    echo -n "${the_prompt}$([[ -n "${default}" ]] && echo " [${default}]"): "
    read -e User_Input

    if [[ -n "${User_Input}" ]]; then
      break
    elif [[ -n "${default}" ]]; then
      User_Input="${default}";
      break
    fi

  done

}


function get_hash () 
{ 
    local the_f="${1}"; shift                    # The file
    local the_h="'$(sha256sum "${the_f}")'";  # The hash
    echo "sha256sum -c -<<<${the_h}"
}


function upload_file() {
  # Uses rsync to upload the file and returns the sha256sum
  # Global variable utilized

  if ! ${Force}; then  # If the -F is used, then no verification is done
    local User_Input=""  # is used in show_prompt function
    echo -e "\nUploading ${THE_FILE} to ${THE_SERVER}${THE_DOMAIN}${TARGET_DIR} as ${THE_USER}?"
    show_prompt -d 'n' "Confirm to continue ('y')"
  else
    local User_Input="y"
  fi

  if [[ "${User_Input}" == "y" ]]; then
    rsync -avP "${THE_FILE}" ${THE_USER}@${THE_SERVER}${THE_DOMAIN}${TARGET_DIR}
    echo -e "\n$(get_hash "${THE_FILE}")\n"  # buffer hash-in-sha command with newlines
  else
    echo ""
    usage "ABORTED! Nothing was uploaded."
  fi
}


function interactive_mode() {
  # Get's necessary variables from user interactively
  
  local User_Input=""  # is used in show_prompt function
  if [[ -z "${THE_USER}" ]]; then
    show_prompt -d "$(whoami)" "The user"
    THE_USER="${User_Input}"; User_Input=""
  fi
  if [[ -z "${THE_SERVER}" ]]; then
    show_prompt "The server"
    THE_SERVER="${User_Input}"; User_Input=""
  fi
  if [[ "${TARGET_DIR}" == ':' ]]; then
    show_prompt -d ':' "The target directory"
    TARGET_DIR="$( [[ "$User_Input" != ":" ]] && echo ":" )${User_Input}"; User_Input=""  # Procede with ':' if value is other than ':'
  fi
  if [[ -z "${THE_FILE}" ]]; then
    show_prompt "The file"
    THE_FILE="${User_Input}"; User_Input=""
  fi

  if [[ ! -f "${THE_FILE}" ]]; then
    usage "I can't find file: ${THE_FILE}. Are you in the right directory?"
  fi

  upload_file
}


function opt_2_actions() {
  # Parses options and does the needful per the options

  # defaults to 'false'
  ##JH local int_mode=false
  ##JH local has_user=false
  ##JH local has_server=false
  ##JH local has_t_dir=false
  ##JH local has_file=false
  local Force=false
  local OPTIND OPTION i u s d f F
  while getopts "iu:s:d:f:F" OPTION; do
    case "$OPTION" in
      'i' )  # interactive mode
        local int_mode=true
        ;;
      'u' )  # designate a user (default will get user from 'whoami')
        THE_USER="$OPTARG"
        local has_user=true
        ;;
      's' )  # designate a server
        THE_SERVER="$OPTARG"
        local has_server=true
        ;;
      'd' )  # designate a target directory if there is one
        TARGET_DIR=":$OPTARG"
        local has_t_dir=true
        ;;
      'f' )  # desgnate the filename
        THE_FILE="$OPTARG"
        local has_file=true
        ;;
      'F' )  # Force (true if designated)
        Force=true
        ;;
      ? )
        usage
        ;;
    esac
  done

  ##JH if ${int_mode} ; then
    interactive_mode

  ##JH else
  ##JH 
  ##JH   if ! ${has_user} ; then
  ##JH     THE_USER="$(whoami)"
  ##JH   fi
  ##JH 
  ##JH   if ! ${has_server} ; then
  ##JH     usage "Where are we sending the file? Please specify a target server hostname."
  ##JH   elif ! ${has_file} ; then
  ##JH     usage "What are we uploading? Please specifie a file to upload."
  ##JH   elif [[ ! -f "${THE_FILE}" ]]; then
  ##JH     usage "I can't find file: ${THE_FILE}. Are you in the right directory?"
  ##JH   fi
  ##JH 
  ##JH   upload_file
  ##JH 
  ##JH fi
}


function check_domain() {
  # manages domain specification

  if [[ -z "${THE_DOMAIN}" ]]; then
    local User_Input=""
    show_prompt "No domain is hard-coded. Continue without a specified domain (y/n)?"
    local ysno="${User_Input}"; User_Input=""

    if [[ "${ysno}" != 'y' ]]; then
      show_prompt "Specify domain with preceding \".\" (type 'EXIT' or 'CTRL+c' to quit)"
      if [[ "${User_Input}" != "EXIT" ]]; then
        THE_DOMAIN="${User_Input}"; unset User_Input
      else
        usage "Quitting with no domain!"
      fi
    fi

  fi
}


function main() {
  # The main event

  THE_DOMAIN=""  ## Include the "." before the domain name
  check_domain
  THE_USER=""
  THE_SERVER=""
  TARGET_DIR=':'
  THE_FILE=""
  opt_2_actions "${@}"
}


main ${@}
