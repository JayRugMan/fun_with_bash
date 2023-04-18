#!/bin/bash

echo -e "\n - Getting OS and package management info."
if grep "ID_LIKE" /etc/os-release >/dev/null 2>&1; then
  the_os=$(awk -F'=' '/^ID_LIKE=/ {print $2}')
else
  the_os=$(awk -F'=' '/^ID=/ {print $2}')
fi

case "$the_os" in
  "fedora" )
    package_manager_command="rpm -qa" ;;
  "ubuntu" )
    package_manager_command="dpkg -l" ;;
  "arch" )
    package_manager_command="pacman -Q" ;;
  * )
    echo -e "\n -- Sorry, this script is not built to handle ${the_os}'s package manager. Exiting."
    exit 1
    ;;
esac

echo -e "\n - Updating locate DB."
updatedb

echo "\n - Checking for log4j vulnerability"
if [ "$(locate log4j | grep -v log4js)" ]; then
  echo " -- maybe vulnerable, those files contain the name:"
  locate log4j | grep -v log4js;
fi

if [ "$(${package_manager_command} | grep log4j | grep -v log4js)" ]; then
  echo " -- maybe vulnerable, installed packages:"
  ${package_manager_command} | grep log4j
fi

if [ "$(which java)" ]; then
  echo " -- java is installed, so note that Java applications often bundle their libraries inside jar/war/ear files, so there still could be log4j in such applications."
fi

echo -e "\n - If you see no output above this line, you are safe. Otherwise check the listed files and packages."
