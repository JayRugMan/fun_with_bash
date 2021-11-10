#!/bin/bash
input="$*"
IFS=$'\n'
ytCurlSearch="curl -s https://www.youtube.com/results?search_query="
grepFilter='grep -oE "watch\?v=[0-9a-zA-Z_-]{11}"'
ytHTTPSstr="https://www.youtube.com"

if [[ -z $input ]]; then 
  echo -e "Need a sting to search - exiting\n try again"
  exit 1
fi

# Cleans spaces by replacing with "+" 
searchString="$(echo "${input}" | sed 's/&//g;s/  / /g;s/ /+/g')"

## Searched youtube in chrome and puts the top "watch" result in an arg
# filters curl results for the top video result
topResult="$(echo "${ytCurlSearch}${searchString} | ${grepFilter} | head -1" | sh)"
# Adds the filtered curl output and appends to 
# yt https sting to make a complete URL
resultVidURL="${ytHTTPSstr}/${topResult}"

echo -e "$resultVidURL"
