#!/bin/bash
# This script depends on tcpdump and iproute
# Captures tcp packets on a desgnated interface

function usage() {
  cat <<EOF

Usage:

-h                      prints usage (this)
-i <interface>          designates interface (eth0 or br0)

Note:
- if no args are provided, dialogue will ask for interface
- the command run is 
#    tcpdump -i <chosen Interface> -nn -s0 -vv -w tcpdump_<interface>_\$(date +%Y%m%d-%H%M%S).pcap


EOF
}

option=${1}

# set up an array of interfaces
interfaceList=($(ip link show | awk '/^[1-9]/ {print substr($2, 1, length($2)-1)}'))
declare -A ifacesarray
for name in ${interfaceList[@]}; do 
  ifacesarray["$name"]=1
done

if [[ -z $option ]]; then
  option="int"
fi

case $option in
  -h )
    usage
    exit 0
    ;;
  -i )
    if [[ -z ${2} ]] || [[ ! ${ifacesarray["$2"]} ]] ; then
      usage
    else
      iface=${2}
    fi
    ;;
  int )
    while true; do
      echo -n "for usage, run with -h - Which interface?(${interfaceList[@]}) "
      read -e iface
      if [[ ${ifacesarray["$iface"]} ]]; then
        break
      else
        echo "invalid interface"
      fi
    done
    ;;
esac

outputFile="tcpdump_${iface}_$(date +%Y%m%d-%H%M%S).pcap"
tcpdump -i $iface -nn -s0 -vv -w $outputFile && echo "see results with \"tcpdump -r $outputFile | less\""
