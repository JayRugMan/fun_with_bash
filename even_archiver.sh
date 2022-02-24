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
  THE_FILES=( $(find . -type f -exec du -sb {} \; 2>/dev/null| sort -n| sed 's/\t/ /g') )
  unset IFS
}


function calc_tot_capacity() {
  # Calculates the total, uncompressed capacity of the files to be archived
  total=0
  for i in ${FILE_SIZES[@]}; do
    total=$((total + i))
  done
  echo $total && unset total
}


function calc_archv_count() {
  # This takes the number of files and tar size limit
  # to determine the number of final tar files

  ##JH tar_size_limit=536870912  # 512M
  tar_size_limit=21474836480  # 20G
  ##JH tar_size_limit=10737418240  # 10G
  t_cap=$1
  tar_file_count=$((t_cap / tar_size_limit))

  # if the total capacity is less than the tar_size_limit, then tar_file_count
  # will be 0, which won't work. This makes it at least one. Additionally, if
  # there is just shy of two, the arithmatic will round down to 1, meaning an
  # archive could end up with just shy of 40G. To avoid that, 1 becomes 2.
  if [[ "$tar_file_count" -le 1 ]]; then
    ((tar_file_count++))
  fi
  
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
  unset h_card t_card hand
}


function build_lists() {
  # builds lists for tar commands

  file_count=${#THE_FILES[@]}
  total_cap=$(calc_tot_capacity)
  arch_file_count=$(calc_archv_count $total_cap)
    
  if [[ "$arch_file_count" -gt 1 ]]; then
    
    half_file_count=$((file_count/2))
    high_card=$((file_count - 1))
    low_card=0
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
  
  else
  
    for file_index in ${!FILE_NAMES[@]}; do
      ARCH_LISTS[1]+="\"${FILE_NAMES[${file_index}]}\" "
    done

  fi
}


function and_now_archive() {
  # Archives
  the_file="${1}"
  for i in ${!ARCH_LISTS[@]}; do
    echo "tar cvzf ${the_file}${i}.tgz ${ARCH_LISTS[$i]}" | sh
    echo -e "\n"
  done
}


function main() {
  ## SET ARGS ##
  declare -a THE_FILES; get_files
  declare -A ARCH_LISTS
  FILE_SIZES=(${THE_FILES[@]%% *})
  FILE_NAMES=("${THE_FILES[@]#* }")
  target_base="/mnt/backups"
  target_file="${target_base}/media_backups_plex01_$(date +%Y%m%d_%H%M)_init_Movies-"
  ####
  build_lists
  and_now_archive "${target_file}"
}

main
