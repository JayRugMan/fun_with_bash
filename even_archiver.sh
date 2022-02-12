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
  echo $total && unset total
}


function calc_archv_count() {
  # This takes the number of files and tar size limit
  # to determine the number of final tar files

  tar_size_limit=26843545600  # 25G
  t_cap=$1
  tar_file_count=$((t_cap / tar_size_limit))

  # if the capacity does divide evenly by 25G and there is
  # more than 5G left, it adds another tar file to the count
  if [[ $((t_cap % tar_size_limit)) -gt 5368709120 ]]; then
    ((tar_file_count++))
  fi
  echo $tar_file_count
}


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

declare -a totals
t_idx=0                # will increase with each itteration of "while" loop
ht_factor=1            # will increase with each itteration of "while" loop

while [[ "$t_idx" -lt "$half_file_count" ]]; do
  theA=$(echo "$the_files"| head -${ht_factor}| tail -1)
  theB=$(echo "$the_files"| tail -${ht_factor}| head -1)
  totals[$t_idx]=$(echo "$theA + $theB"| bc)
  ((tidx++)); ((ht_factor++)); unset theA theB
done

unset tidx the_beg the_end the_files
