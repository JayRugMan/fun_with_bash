#!/bin/bash
# This script depends on tcpdump and iproute
# Captures tcp packets on a desgnated interface


function usage() {
  local array="$1[@]"
  cat <<EOF

Usage:

-i <interface>          designates interface (${!array})
*                       prints usage (this)

Note:
- if no args are provided, dialogue will ask for interface
- the command run is
#    tcpdump -i <chosen Interface> -nn -s0 -vv -w tcpdump_<interface>_\$(date +%Y%m%d-%H%M%S).pcap

EOF
}


function is_in() {
  local array="$1[@]"
  local seeking="$2"
  local in=1
  for element in "${!array}"; do
    if [[ "$element" == "$seeking" ]]; then
      in=0
      break
    fi
  done
  return $in
}


if [[ -z "${1}" ]]; then
  option="int"
else
  option="${1}"
fi

# set up an array of interfaces
ifaces=($(ip link show | awk '/^[1-9]/ {print substr($2, 1, length($2)-1)}'))

case "$option" in
  -i )
    if [[ -v ${2} ]] && (is_in ifaces "${2}") ; then
      iface=${2}
    else
      usage ifaces
      exit 1
    fi
    ;;
  int )
    while true; do
      echo -n "for usage, run with -h - Which interface?(${ifaces[@]}) "
      read -e iface
      if (is_in ifaces "$iface") ; then
        break
      else
        echo "invalid interface"
      fi
    done
    ;;
  * )
    usage ifaces
    exit 0
    ;;
esac

outputFile="tcpdump_${iface}_$(date +%Y%m%d-%H%M%S).pcap"
tcpdump -i $iface -nn -s0 -vv -w $outputFile && echo "see results with \"tcpdump -r $outputFile | less\""
