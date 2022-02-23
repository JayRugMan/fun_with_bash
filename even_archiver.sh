#!/usr/bin/env bash
# Created by Jason Hardman, jasonrhardman@gmail.com
# on 2022 Feb 12
# Last modified 20220212
# Description:
#    This script is to evenly archive my massive movie library.
#    File sizes range from just under 100 Megs to a few Gigs, so
#    the idea is to arrange the files in all sub-directories in
#    order by capacity, then pair the largest with the smallest
#    until all movies are paired, then repeat the process. if
#    there is an odd number of files, then the "middle" file is
#    added to an arbitrary archive. Pairs are then paired with
#    other pairs until a small but evenly distributed number of
#    archive files are created - each containing roughly the same
#    size and number of files.


function get_files() {
  # Uses crafted find command to get all of the files
  IFS=$'\n'
  THE_FILES=( $(find . -type f -exec du -sb {} \;| sort -n| sed 's/\t/ /g') )
  unset IFS
}


function calc_tot_capacity() {
  # Calculates the total, uncompressed capacity of the files to be archived
  capacities=(${@})
  total=0
  for i in ${capacities[@]}; do
    total=$((total + i))
  done
  echo $total && unset total capacities
}


function calc_archv_count() {
  # This takes the number of files and tar size limit
  # to determine the number of final tar files

  tar_size_limit=21474836480  # 20G
  ##JH tar_size_limit=10737418240  # 10G
  t_cap=$1
  tar_file_count=$((t_cap / tar_size_limit))

  # if the capacity doesn't divide evenly by 10G and there
  # is more than 3G left, or if the total capacityu is less
  # than 10G, it adds another tar file to the count
  ##JH if [[ $((t_cap % tar_size_limit)) -gt 3221225472 ]] || [[ "$tar_file_count" -eq 0 ]]; then
  ##JH   ((tar_file_count++))
  ##JH fi
  echo $tar_file_count
  unset tar_size_limit t_cap tar_file_count
}


function deal_me_in() {
  # "deals card," or distributes file names to archive lists per deal order
  h_card="${1}"; shift
  l_card="${1}"; shift
  for hand in ${@}; do
    ARCH_LISTS[$hand]+="\"${FILE_NAMES[$h_card]}\" \"${FILE_NAMES[$l_card]}\" "
  done
  unset h_card t_card
}


function build_lists() {
  # builds lists for tar commands

  file_count=${#THE_FILES[@]}
  half_file_count=$((file_count/2))
  high_card=$((file_count - 1))
  low_card=0
  total_cap=$(calc_tot_capacity ${FILE_SIZES[@]})
  arch_file_count=$(calc_archv_count $total_cap)
  twice_afc=$((arch_file_count * 2))
  direction="right"

  while [[ "$low_card" -lt "$half_file_count" ]]; do

    hi_lo_diff=$((high_card - low_card))
    if [[ "${hi_lo_diff}" -lt "$twice_afc" ]]; then
      break
    fi

    case "$direction" in
      "right")
        deal_order=($(seq 1 "$arch_file_count"))
        deal_me_in "$high_card" "$low_card" ${deal_order[@]}
        direction="left"
        ;;
      "left")
        deal_order=($(seq "$arch_file_count" -1 1))
        deal_me_in "$high_card" "$low_card" ${deal_order[@]}
        direction="right"
        ;;
    esac

    high_card=$((high_card - arch_file_count))
    low_card=$((low_card + arch_file_count))

  done

  last_hand=$((arch_file_count + 1))
  for remainders in $(seq 0 "$hi_lo_diff"); do
    if [[ -z "${ARCH_LISTS[$last_hand]}" ]]; then
      ARCH_LISTS[$last_hand]="\"${FILE_NAMES[$low_card]}\" "
    else
      ARCH_LISTS[$last_hand]+="\"${FILE_NAMES[$low_card]}\" "
    fi
    ((low_card++))
  done
}


function and_now_archive() {
  # Archives
  for i in ${!ARCH_LISTS[@]}; do
    echo "tar cvzf /mnt/backups/media_backups_plex01_$(date +%Y%m%d_%H%M)_init_Movies-${i}.tgz ${ARCH_LISTS[$i]}" | sh
    echo -e "\n"
  done
}


function main() {
  ## SET ARGS ##
  declare -a THE_FILES; get_files
  declare -A ARCH_LISTS
  FILE_SIZES=(${THE_FILES[@]%% *})
  FILE_NAMES=("${THE_FILES[@]#* }")
  ####
  build_lists
  and_now_archive
}

main
