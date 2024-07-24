#!/bin/bash

FILE="${1}"; shift

file_birth_sec=$(stat -c "%W" "${FILE}")

if [[ ${file_birth_sec} -eq 0 ]]; then
  echo "Looks like file birthday is unknown"
  exit 1
fi

now_time_sec=$(date +%s)
diff_time_sec=$((now_time_sec - file_birth_sec))
days=$((diff_time_sec / 86400))
hours=$((diff_time_sec % 86400 / 3600))
minutes=$(((diff_time_sec % 86400) % 3600 / 60))
seconds=$((((diff_time_sec % 86400) % 3600) % 60))

echo "${days}d"
echo "File Age: days:${days}, hours:${hours}, minutes:${minutes}, seconds:${seconds}"