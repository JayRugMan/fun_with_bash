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


function calc_tot_capacity(){
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
}


## SET ARGS ##
IFS=$'\n'
  the_files=($(find . -type f -exec du -sb {} \;| sort -n| sed 's/\t/ /g'))
unset IFS

file_sizes=(${the_files[@]%% *})
file_names=("${the_files[@]#* }")
file_count=${#the_files[@]}
half_file_count=$((file_count/2))

total_cap=$(calc_tot_capacity ${file_sizes[@]})
is_odd=$([[ $((file_count%2)) -eq 1 ]] && echo "true" || echo "false")
arch_file_count=$(calc_archv_count $total_cap)

declare -A arch_lists=()

for arch_num in $(seq 1 "$arch_file_count"); do
  arch_lists[$arch_num]=0;
done
twice_afc=$((arch_file_count * 2))
high_card=$((file_count - 1))
low_card=0
direction="right"
##

while [[ "$low_card" -lt "$half_file_count" ]]; do

  hi_lo_diff=$((high_card - low_card))
  if [[ "${hi_lo_diff}" -lt "$twice_afc" ]]; then
    break
  fi

  case "$direction" in
    "right")
      for hand in $(seq 1 "$arch_file_count"); do
        arch_list[$hand]+="\"${file_names[$high_card]}\" \"${file_names[$low_card]}\" "
        ((high_card--))
        ((low_card++))
      done
      direction="left"
      ;;
    "left")
      for hand in $(seq "$arch_file_count" -1 1); do
        arch_list[$hand]+="\"${file_names[$high_card]}\" \"${file_names[$low_card]}\" "
        ((high_card--))
        ((low_card++))
      done
      direction="right"
      ;;
  esac

done

last_hand=$((arch_file_count + 1))
for remainders in $(seq 0 "$hi_lo_diff"); do
  if [[ -z "${arch_list[$last_hand]}" ]]; then
    arch_list[$last_hand]="\"${file_names[$low_card]}\" "
  else
    arch_list[$last_hand]+="\"${file_names[$low_card]}\" "
  fi
  ((low_card++))
done

for i in ${!arch_list[@]}; do
  echo "tar cvzf /mnt/backups/media_backups_plex01_$(date +%Y%m%d_%H%M)_init_Movies-${i}.tgz ${arch_list[$i]}" | sh
  echo -e "\n"
done
