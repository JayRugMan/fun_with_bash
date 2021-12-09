#!/bin/bash
## I can't remember where I got the original of this script, but I've modified some and offer it freely
## Modified by Jason Hardman

# Regex of Linux Kernel version number
verRegex="[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,3}-[0-9]{1,3}"

# Regex to filter for installed Linux Kernels
linuxpkgRegex="linux-(image|headers|ubuntu-modules|restricted-modules)"

# Regex to filter out meta-packages
meta_linuxpkgRegex="linux-(image|headers|restricted-modules)-(generic|i386|server|common|rt|xen)"

# Last two Kernel version packages (just the number)
lastTwoKernVers="$(dpkg -l | awk '{print $2}' | grep -E $linuxpkgRegex | grep -oE "$verRegex" | sort -V -u | tail -2)"

# All but last two Linux Kernel versions
allButLastTwoKernVers="$(ls -1 /boot/ | grep -Eo "$verRegex" | sort -V -u | head -n -2)"

# All but last two installed Linux kernels
oldKernels="$(dpkg -l | awk -v lpkg=$linuxpkgRegex ' $0 ~ lpkg {print $2}' | grep -vE $meta_linuxpkgRegex | grep -v "$lastTwoKernVers")"

# Checks whether more than two kernels exist on the system, then cleans if more than two
if [[ -z "${oldKernels}" ]]; then
  # No more than two kernels found
  echo -e "No more than two kernels found. Exiting\n"
  exit 1
else
  echo -e "\nMore than two kernels found. Removing"
  # Purge all but last two kernels from the system:
  apt-get purge "$oldKernels"

  # Clean up boot directory of older kernel files
  for ver in ${allButLastTwoKernVers}; do
    echo "rm -vf /boot/*${ver}*" | sh
  done
fi
