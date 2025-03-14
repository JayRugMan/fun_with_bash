#!/bin/bash

# Directory where AppImages and Desktop files are stored
app_dir="${HOME}/apps"
desktop_dir="${HOME}/.local/share/applications"

# Name of the symbolic link
link_name="${app_dir}/Bitwarden"

# Find the latest Bitwarden AppImage
latest_appimage=$(ls -t "${app_dir}"/Bitwarden*.AppImage | head -n 1)

# Check if an AppImage was found
if [ -z "${latest_appimage}" ]; then
    echo "No Bitwarden AppImage found in ${app_dir}"
    exit 1
fi

# Remove the old symbolic link if it exists
[ -L "${link_name}" ] && unlink "${link_name}"

# Create a new symbolic link to the latest AppImage
ln -s "${latest_appimage}" "${link_name}"

echo "Symbolic link updated to: ${latest_appimage}"

# Fix the broken desktop file
if alacarte_made="$(grep -Rl BitWarden ${desktop_dir}/| grep "alacarte-made.*desktop" | head -n 1)"; then
  mv "${alacarte_made}" ${desktop_dir}/BitWarden.desktop 2>/dev/null&& \
  echo "Changed alacarte desktop file back to BitWarden.desktop" || \
  echo "Failed to Change alacarte desktop file back to BitWarden.desktop"
elif ! [ -f ${desktop_dir}/BitWarden.desktop ]; then
  cp ${app_dir}/BitWarden.desktop ${desktop_dir}/BitWarden.desktop
  echo "Coppied BitWarden.desktop back into ${desktop_dir}" 
fi
update-desktop-database ${desktop_dir}/

echo "Desktop updated"