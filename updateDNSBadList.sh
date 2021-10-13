#!/bin/bash
# This script is to bring various hosts files with bad sites, like ads
# porn, gambling from around the web, download them, then compile them
# into one file for dnsmasq to use

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

### Customization ###

COMPILE_DIR="/root/Documents/dns"
NAUGHTY_LIST_FILE="/etc/badList_hosts"
# -- Make sure the index of each remote hosts file lines up with each local hosts file, 
# and that there are the same or more items in the Local Hosts File
REMOTE_HOSTS_FILES=(https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/gambling-porn-social/hosts https://www.github.developerdan.com/hosts/lists/ads-and-tracking-extended.txt)
LOCAL_HOSTS_FILES=(gamPorSo_hosts ads-and-tracking-extended.txt badList_hosts.bak)
COMPILATION_FILE="HostsBlockCompilation"
WHITELIST="$COMPILE_DIR/dnsWhite.lst"

### END Customization ###


function gather_remote_hosts() {
  # Gathers hosts files listed in remoteHostsFiles array
  remoteCount=$((${#REMOTE_HOSTS_FILES[@]}-1))
  for i in $(seq 0 ${remoteCount}); do
    /usr/bin/wget -O $COMPILE_DIR/${LOCAL_HOSTS_FILES[$i]} ${REMOTE_HOSTS_FILES[$i]}
  done
}


function catcatonate_compile() {
  # puts it all together after backing up the previous three
  catString="cat"
  for i in ${LOCAL_HOSTS_FILES[@]}; do
    catString="$catString $COMPILE_DIR/$i"
  done
  # filters out hostnames from the whitelist if it exists
  if [[ -f $WHITELIST ]]; then
    catString="$catString | grep -vFf $WHITELIST "
  fi
  /bin/cp $COMPILE_DIR/$COMPILATION_FILE.2.bak $COMPILE_DIR/$COMPILATION_FILE.3.bak
  /bin/cp $COMPILE_DIR/$COMPILATION_FILE.bak $COMPILE_DIR/$COMPILATION_FILE.2.bak
  /bin/cp $COMPILE_DIR/$COMPILATION_FILE $COMPILE_DIR/$COMPILATION_FILE.bak
  echo "# For comments, see ${LOCAL_HOSTS_FILES[*]} in $COMPILE_DIR" > $COMPILE_DIR/$COMPILATION_FILE
  catString="$catString | sort -u | egrep -v '[ ]{0,}#|^$' >> $COMPILE_DIR/$COMPILATION_FILE"
  echo "$catString" | /bin/sh
}


function publish_and_update() {
  # puts file in place in /etc and restarts dnsmasq
  /bin/cp $COMPILE_DIR/$COMPILATION_FILE $NAUGHTY_LIST_FILE
  /bin/systemctl stop dnsmasq && /bin/systemctl start dnsmasq
}


function main() {
  # Main function
  gather_remote_hosts
  catcatonate_compile
  publish_and_update
}

main
