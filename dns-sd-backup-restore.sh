#!/bin/bash
#
# dns-sd-backup-restore.sh
# Safe backup/restore script for Raspberry Pi SD cards (Arch ARM + DNSMasq)
# Run as root on Linux Mint host

set -euo pipefail

SCRIPT_NAME=$(basename "$0")
IMAGE_DIR="/root"
DEFAULT_IMAGE_NAME="dns-2_os_$(date +%Y%m%d).img"

show_help() {
    cat << EOF
Usage: $SCRIPT_NAME --backup | --restore [options]

Options:
  -b, --backup     Create a backup of an SD card
  -r, --restore    Restore an image to an SD card (and auto-expand root partition)
  -h, --help       Show this help message

Examples:
  $SCRIPT_NAME --backup
  $SCRIPT_NAME --restore /root/dns-2_os_20260506.img.gz

The script will always show lsblk and ask for confirmation before doing anything destructive.
It now checks whether the chosen device (or its partitions) are currently mounted.
EOF
}

confirm() {
    local prompt="$1"
    read -r -p "$prompt [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            return 0
            ;;
        *)
            echo "Aborted."
            return 1
            ;;
    esac
}

# Get list of critical mountpoints (root, boot, etc.)
get_critical_mounts() {
    local critical=()
    for mp in / /boot /boot/efi /boot/efi2; do
        if mountpoint -q "$mp" 2>/dev/null; then
            critical+=("$mp")
        fi
    done
    printf '%s\n' "${critical[@]}"
}

# Check if any partition of $1 is mounted, and whether it's critical
check_mounted() {
    local dev="$1"
    local critical_mounts
    critical_mounts=$(get_critical_mounts)

    # Get all mounted partitions that belong to this disk
    local mounted_parts
    mounted_parts=$(findmnt -rn -o TARGET,SOURCE | awk -v d="$dev" '$2 ~ d {print $1}')

    if [[ -z "$mounted_parts" ]]; then
        return 0   # nothing mounted from this device
    fi

    echo -e "\nWARNING: The following mountpoints are currently active on $dev:"
    echo "$mounted_parts"
    echo

    for mp in $mounted_parts; do
        for crit in $critical_mounts; do
            if [[ "$mp" == "$crit" || "$mp" == "$crit/"* ]]; then
                echo "ERROR: $dev contains a partition mounted at a critical location ($mp)."
                echo "Refusing to continue — this looks like a system disk."
                return 1
            fi
        done
    done

    # Non-critical mounts found
    echo "These are non-system mounts."
    if ! confirm "Do you want to unmount them before continuing?"; then
        echo "Aborting unmount. Please choose a different device."
        return 1
    fi
    for mp in $mounted_parts; do
        echo "Unmounting $mp..."
        umount "$mp" || {
            echo "Failed to unmount $mp. Please unmount manually and try again."
            return 1
        }
    done
    echo "All partitions unmounted."
}

get_device() {
    echo -e "\n=== Current block devices ==="
    lsblk -f
    echo
    while true; do
        read -r -p "Enter the device name (e.g. sdb, mmcblk0): " dev
        dev="/dev/${dev#/dev/}"   # normalize

        if [[ ! -b "$dev" ]]; then
            echo "ERROR: $dev is not a valid block device, try again."
            continue
        fi
        
        if check_mounted "$dev"; then  # Dynamic safety check: is anything on this device mounted to critical paths?
            echo "$dev"
            return 0
        else
            echo -e "Please choose a different device.\n"
        fi
    done
}

do_backup() {
    local dev
    dev=$(get_device)

    echo -e "\nYou are about to BACK UP: $dev"
    lsblk "$dev"
    if ! confirm "This will overwrite any existing backup. Continue?"; then
        echo "Aborting."
        exit 1
    fi 

    local outfile="$IMAGE_DIR/$DEFAULT_IMAGE_NAME"
    echo -e "\nBacking up $dev → $outfile (this will take a while)..."

    dd if="$dev" of="$outfile" bs=4M status=progress conv=sparse
    sync

    echo -e "\nCompressing..."
    gzip -9 "$outfile"

    echo -e "\nBackup complete: ${outfile}.gz"
    ls -lh "${outfile}.gz"
}

do_restore() {
    local image="$1"
    local dev

    if [[ -z "$image" ]]; then
        echo "ERROR: You must specify the image file to restore."
        echo "Example: $SCRIPT_NAME --restore /root/dns-2_os_20260506.img.gz"
        exit 1
    fi

    if [[ ! -f "$image" ]]; then
        echo "ERROR: Image not found: $image"
        exit 1
    fi

    dev=$(get_device)

    echo -e "\nYou are about to RESTORE to: $dev"
    lsblk "$dev"
    echo -e "\nWARNING: This will COMPLETELY WIPE $dev"
    if ! confirm "Are you absolutely sure?"; then
        echo "Aborting restore."
        exit 1
    fi

    echo -e "\nRestoring $image → $dev ..."

    if [[ "$image" == *.gz ]]; then
        gunzip -c "$image" | dd of="$dev" bs=4M status=progress conv=sparse
    else
        dd if="$image" of="$dev" bs=4M status=progress conv=sparse
    fi
    sync

    echo -e "\nRestore finished. Now expanding root partition to fill the card..."

    # Proper resize sequence (e2fsck first!)
    e2fsck -f "${dev}2" -y || true
    parted "$dev" resizepart 2 100%
    resize2fs "${dev}2"

    echo -e "\nDone. Final layout:"
    lsblk "$dev"
    echo -e "\nCard is ready to boot on the Pi (full size, no manual expansion needed)."
}

# === Main ===

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: This script must be run as root (use sudo -i)"
    exit 1
fi

case "${1:-}" in
    -b|--backup)
        do_backup
        ;;
    -r|--restore)
        do_restore "${2:-}"
        ;;
    -h|--help|"")
        show_help
        ;;
    *)
        echo "Unknown option: $1"
        show_help
        exit 1
        ;;
esac

