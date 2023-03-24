#!/bin/bash


function get_device() {

  serial="${1}"
  
  local drive="$(lshw -quiet -class disk | awk -v my_serial="$serial" '
    $0~/logical name/ {
      lineno=NR;
      text=$3
    }
    NR=lineno+2 && $0~my_serial {
      print text
    }
    ')"
  echo "$drive"
}


function map_to_devices(){

  serials=( ${@} )

  echo -ne "Serial nums to devices: mapping..."
  
  for i in ${!serials[@]}; do
    device_full_path="$(get_device "${serials[$i]}")"
    if [[ -z "$device_full_path" ]]; then
      echo -e "\b\b\b\b\b\b\b\b\b\bfailed     "
      usage "One or more of the needed drive is not found"
      exit 1
    fi
    DEVICES[$i]=${device_full_path##*/}
  done

  echo -e "\b\b\b\b\b\b\b\b\b\bmapped     "

  unset device_full_path
}


function luks_open() {
  
  read -s the_pw
  
  for device in ${DEVICES[@]} ; do
    
    mnt_pnt=${MNT_BASE}-${device}

    if [[ ! -d "${mnt_pnt}" ]]; then
      mkdir ${mnt_pnt} && \
      chown ${USER}: ${mnt_pnt}
    fi

    echo -n "${the_pw}" | cryptsetup luksOpen /dev/${device}1 jrnl-${device} -d - && \
    mount /dev/mapper/jrnl-${device} ${mnt_pnt} && \
    chown -R ${USER}: ${mnt_pnt}

    exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
      usage "Passphrase incorrect"
      exit $exit_code
    fi

  done
  
  END_MESSAGE="edit ${DEVICES[0]}, which will copy to ${DEVICES[1]}"
  unset the_pw device mnt_pnt
}


function luks_close() {

  rsync -Aavp ${MNT_BASE}-${DEVICES[0]}/* ${MNT_BASE}-${DEVICES[1]}/
  sync
  
  for device in ${DEVICES[@]} ; do
    umount ${MNT_BASE}-${device} && \
    cryptsetup luksClose jrnl-${device} && \
    eject /dev/${device}
  done
  
  unset device
  END_MESSAGE="Both drives are ready to be removed."
}


function usage() {
  if [[ ! -z "${@}" ]]; then
    echo -e "ERROR: ${@}"
  fi
  cat <<EOF
USAGE:

  -o    Opens the two drives

  -c    Closes the two drives

  *     Anything else gets you
        this informative help
        stuff.

Thanks
EOF
exit 1
}


function main() {

  option="${1}"

  # Serial numbers of the two thumbdrives. Update accordingly, using the following command:
  #     lshw -quiet -class disk
  serial_a="4C530000150509111301"
  serial_b="4C530000060509111233"

  declare -a DEVICES
  END_MESSAGE=""
  USER="jason"
  MNT_BASE="/media/${USER}/Journal"

  case $option in
    -o)
      map_to_devices "$serial_a" "$serial_b"
      luks_open;;
    -c)
      map_to_devices "$serial_a" "$serial_b"
      luks_close;;
    *)
      usage ;;
  esac

  lsblk
  printf  "\n-- %s --\n" "$END_MESSAGE"
}


main "${1}"
