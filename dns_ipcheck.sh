#!/bin/bash
# Designed to find the appropriate ip address for a host, either hardline nic or wireless, and update that to the /etc/hosts file for dnsmasq

function get_ip() {
  # Gets the ip address for the given host
  local tests=( ${@} )
  local network="192.168.0"
  local change=false

  for i in ${tests[@]}; do
    if ping -q -w 2 -c 1 ${network}.${i} > /dev/null 2>&1 ; then
      WORKING_IP="${network}.${i}"
      change=true
      break
    fi
  done; unset i

  if ${change} ; then
    return 0
  else
    return 1
  fi
}


function update_working_ip() {
  # Uses sed to replace ip address
  local my_host="${1}"; shift
  local old_ip="$(awk -v"host=${my_host}" '$0~host {print $1}' /etc/hosts)"
  sed -i "s/$old_ip/$WORKING_IP/g" /etc/hosts
}


function main() {
  # The Main Event

  ## GLOBAL ARG #####
  WORKING_IP=""
  ###################
  
  ## local Args ##
  local -a the_hosts=( "host1" "host3" "host3" )
  local ip_endings=()

  for index in ${!the_hosts[@]}; do

    case ${the_hosts[$index]} in
      "host1" )
         ip_endings=( 14 15 );;
      "host2" )
         ip_endings=( 12 13 );;
      "host3" )
         ip_endings=( 20 21 );;
    esac

    if get_ip ${ip_endings[@]}; then  # WORKING_IP is updated here
      update_working_ip "${the_hosts[$index]}"  # WORKING_IP is used here with sed to update hosts file
    fi

    WORKING_IP=""; ip_endings=()

  done; unset index
  
  systemctl restart dnsmasq.service  # restart dnsmasq to update with new hosts entries
}

main
