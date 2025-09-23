#!/bin/bash

function usage() {
	if [[ ${1} ]]; then
		echo "Error: ${1}"
	fi
	cat <<EOF

USAGE: ${0} [ setup | cleanup ] <disk file>

EOF
}

function setup() {
	disk="${1}"; shift
	echo "---- Getting info for ${disk}"
	info="$(qemu-img info ${disk})" || usage "    Disk File \"${disk}\" Not found. Exiting." ; exit 1
	fmat="$(echo ${info} | awk '/file format:/{print $3}')"
	echo "---- Connecting ${disk} to /dev/nbd0 as ${fmat}"
	qemu-nbd --connect=/dev/nbd0 ${disk} --format=${fmat}
	blk_dev="$(lsblk | awk 'BEGIN{hold=""}; /nbd0/ {hold=$1}; END{print hold}' | sed 's/└─//g')"
	disk_type="$(fdisk -l /dev/nbd0 | awk 'BEGIN{hold=""}; /nbd0/ {hold=$NF}; END{print hold}')"
	if [[ "${disk_type}" == "LVM" ]]; then
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
			mount /dev/${vol} /mnt/${vol}
		done
	fi
}

function cleanup() {
	disk="$(ps aux | grep qemu-nbd | grep -Eo 'connect.*$' | cut -d " " -f 2)"
	if [[ ${disk} ]]; then
		pass
	fi

}

function main() {
	action="${1}"; shift
	disk_file="${1}"; shift
	case "${action}" in
		"setup" )
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

