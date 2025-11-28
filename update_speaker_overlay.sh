#!/bin/bash
# Script to update the overlay SVG file with a new speaker name or date
# Created by Jason Hardman jasonrhardman@protonmail.com

set -euo pipefail

usage() {
  if [[ -n ${@} ]]; then
    echo "Error: ${@}" >&2
  fi
  echo "Usage: $0 [-F|-h] <svg file> <png link> \"<update_text>\""
  cat << EOF

Options:

  -F                   Force update for scripts that expect an existing link.
                       Otherwise prompts for confirmation if the link does not exist.

  -h, --help          Show this help message and exit.

  <svg file>           The SVG file to update (e.g., intermission_overlay.svg)

  <png link>           The symbolic link to the output PNG file (e.g., todays_intro.png)

  <update_text>        The text to replace the placeholder with (e.g., speaker name or date)

EOF
  exit 1
}


main() {
  # args
  if [[ ${1} == "-F" ]]; then force=true; shift; else force=false; fi
  local input_svg="${1}"; shift
  local the_link="${1}"; shift
  local update_text="$*"
  local svg_full_path="$(realpath "${input_svg}")"
  local svg_path="${svg_full_path%/*}"
  local svg_base_name="${input_svg##*/}"

  # remove old link and file if it exists
  if [[ -h "${the_link}" ]] ; then
    local link_full_path="$(realpath ${the_link})"  # absolute it incase it's relative
    local old_file_full="$(realpath "$(readlink "${link_full_path}")")"
    echo "Unlinking ${old_file_full} from ${link_full_path}"
    unlink "${link_full_path}"

    if [[ -f "${old_file_full}" ]] ; then
      echo "Removing old file ${old_file_full}"
      rm -vf "${old_file_full}"
    else
      echo "Dead link, so old file ${old_file_full} does not exist. Skipping removal."
    fi

  elif [[ -e "${the_link}" ]]; then
    # exists, but NOT a symlink
    usage "Error: ${the_link} exists but is not a symlink. Refusing to overwrite."

  else
    echo "No existing link at ${the_link}. Assuming new link should be in ${svg_path}/"
    if ! $force ; then
      read -p "If this is not a problem, press [ENTER] to continue. Otherwise, press [CTRL+C] to abort." _
    fi
    local link_full_path="${svg_path}/${the_link}"  # insure link in svg dir
  fi

  # check svg file exists
  if [[ ! -f "${svg_full_path}" ]] ; then
    usage "SVG file ${svg_full_path} does not exist. Please use relative or absolute path to an existing SVG file."
  fi

  # set output file name
  local output_file="${svg_path}/$(echo "${update_text}" | sed 's/ /_/g')_${svg_base_name%%.*}.png"
  echo "New file will be ${output_file}"

  # sed replace and export png
  local safe_text=$(printf '%s' "$update_text" | sed -e 's/[][\/.^$*]/\\&/g')  # escape for sed
  sed -i "s/REPLACE_ME/${safe_text}/g" "${svg_full_path}"
  inkscape --export-png-color-mode=RGBA_16 -o "${output_file}" "${svg_full_path}"
  sed -i "s/${safe_text}/REPLACE_ME/g" "${svg_full_path}"

  # create new link
  echo "Linking ${output_file} to ${link_full_path}"
  ln -s "${output_file}" "${link_full_path}"
}


case "${1}" in
  -h|--help) usage ;;
  *) ;;
esac

main ${@}