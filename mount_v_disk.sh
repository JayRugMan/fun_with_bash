#!/bin/bash

function usage() {
  if [[ ${1} ]]; then
    echo "Error: ${1}"
  fi
  cat <<EOF

USAGE: ${0} [ setup | cleanup ] <disk file>

EOF
  exit 1
}

function setup() {
  disk="${1}"; shift
  echo "---- Getting info for ${disk}"
  info="$(qemu-img info "${disk}")" || usage "Disk File \"${disk}\" Not found. Exiting."
  fmat="$(echo "${info}" | awk '/^file format:/{print $3}')"
  echo "---- Connecting ${disk} to /dev/nbd0 as ${fmat}"
  qemu-nbd --connect=/dev/nbd0 "${disk}" --format=${fmat}
  blk_dev="$(lsblk | awk 'BEGIN{hold=""}; /nbd0/ {hold=$1}; END{print hold}' | sed 's/└─//g')"
  ##JHdisk_type="$(fdisk -l /dev/nbd0 | awk 'BEGIN{hold=""}; /nbd0/ {hold=$NF}; END{print hold}')"
  disk_type="$(blkid /dev/${blk_dev} | awk 'BEGIN{FS="TYPE=|\""}; {print $5}')"
  if [[ "${disk_type}" == "LVM2_member" ]]; then
    echo "---- LVM, scanning for physical volumes"
    pvscan --cache /dev/${blk_dev} --config 'devices { filter = [ "a|/dev/nbd0|", "r|.*|" ] }'
    echo "---- Scan Volume Group"
    volume_group=$(vgscan --config 'devices { filter = [ "a|/dev/nbd0|", "r|.*|" ] }' | awk -F'\"' '{print $2}')
    echo "Volume group \"${volume_group}\" found"
    echo "---- Activating the found Volume Group ${volume_group}"
    vgchange -ay ${volume_group} --config 'devices { filter = [ "a|/dev/nbd0|", "r|.*|" ] }'
    echo "---- Getting volumes, not swap"
    volumes=( $(ls /dev/${volume_group} | grep -iv "swap") )
    for vol in ${volumes[@]}; do
      if [[ ! -d "/mnt/${vol}" ]] ; then
        echo "---- Making a directory in /mnt for ${vol}"
        mkdir -v "/mnt/${vol}"
      fi
      echo "---- Mounting /dev/${vol} to /mnt/${vol}"
      mount /dev/${volume_group}/${vol} /mnt/${vol}
    done
  else
    echo "---- Not LVM, mounting first partition"
    if [[ ! -d "/mnt/${blk_dev}" ]] ; then
      echo "---- Making a directory in /mnt for ${blk_dev}"
      mkdir -v "/mnt/${blk_dev}"
    fi
    echo "---- Mounting /dev/${blk_dev} to /mnt/${blk_dev}"
    mount /dev/${blk_dev} /mnt/${blk_dev}
  fi
}

function cleanup() {
  disk="$(ps aux | grep qemu-nbd | grep -Eo 'connect.*$' | cut -d " " -f 2)"
  echo "---- Cleaning up mounts for ${disk}"
  mounts=( $(lsblk /dev/nbd0 |  awk '!/NAME/ {if (NF > max_nf) {max_nf = NF; last_fields = $NF} else if (NF == max_nf) {last_fields = last_fields ORS $NF}}; END {print last_fields}' | sort -u) )
  if [[ ${#mounts[@]} -gt 0 ]]; then
    for mnt in ${mounts[@]}; do
      echo "---- Unmounting ${mnt}"
      umount -v "${mnt}"
    done
  else
    usage "No mounts found"
  fi
  volume_group=$(vgdisplay --config 'devices { filter = [ "a|/dev/nbd0|", "r|.*|" ] }' | awk '/VG Name/ {print $3}' | head -n 1)
  mounts_cleared=true
  for mnt in ${mounts[@]}; do
    if mount | grep -q "${mnt}"; then
      mounts_cleared=false
    fi
  done
  if ${mounts_cleared}; then
    echo "---- Deactivating Volume Group \"${volume_group}\""
    vgchange -an ${volume_group} --config 'devices { filter = [ "a|/dev/nbd0|", "r|.*|" ] }'
    echo "---- Disconnecting ${disk} from /dev/nbd0"
    qemu-nbd --disconnect /dev/nbd0
    sync
  else
    usage "Some mounts still exist, not cleaning up LVM or disconnecting nbd"
  fi
}

function main() {
  action="${1}"; shift
  case "${action}" in
    "setup" )
      disk_file="${1}"; shift
      disk_full_path="$(realpath ${disk_file})"
      if [[ ! -f ${disk_full_path} ]]; then
        usage "No disk file provided"
      fi
      setup "${disk_file}"
      ;;
    "cleanup" )
      cleanup
      ;;
    * )
      usage "unknown option" 
      ;;
  esac
}

main "${@}"

