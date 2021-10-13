#!/bin/bash
option="${1}"


function luks_open() {
  read -s the_pw
  for i in a b; do
    echo -n "${the_pw}" | cryptsetup luksOpen /dev/sd${i}1 jrnl${i}  -d - && \
    mount /dev/mapper/jrnl${i} /media/jason/Journal${i} && \
    chown -R jason: /media/jason/Journal${i}
  done
  unset the_pw
}


function luks_close() {
  rsync -Aavp /media/jason/Journala/* /media/jason/Journalb/
  sync
  for i in a b; do
    umount /media/jason/Journal${i} && \
    cryptsetup luksClose jrnl${i} && \
    eject /dev/sd${i}
  done
}


function usage() {
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

case $option in
  -o)
    luks_open ;;
  -c)
    luks_close ;;
  *)
    usage ;;
esac

lsblk

