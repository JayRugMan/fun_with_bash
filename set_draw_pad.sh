#!/bin/bash
# Runs commands to set up wacom tablet

# Wait for device to be ready (especially if Bluetooth connection)
sleep 2

# Get devices if they exist
my_stylus="$(xsetwacom --list devices | awk -F'\t' '/Intuos/ && /type: STYLUS/ {print $1 }')"
my_pad="$(xsetwacom --list devices | awk -F'\t' '/Intuos/ && /type: PAD/ {print $1 }')"

# Test if devices exist
if [[ -z "${my_stylus}" ]] || [[ -z "${my_pad}" ]] ; then
  echo "No usable wacom devices detected"
  exit 1
fi

# clean trailing whitespace
stylus_clean="${my_stylus%"${my_stylus##*[![:space:]]}"}"
pad_clean="${my_pad%"${my_pad##*[![:space:]]}"}"

# How many monitors?
monitor_count=$(xrandr --listmonitors | awk '/Monitors/ {print $2}')

if [[ "${monitor_count}" -gt 1 ]]; then
  if [[ -t 0 ]]; then
    # If there's a terminal
    xrandr --listmonitors
    read -p "More than one monitor detected. Give me the number for the monitor you want to use: " chosen_monitor
  else
    # Else non-interactive default is selected (the highest number, assuming the default laptop monitor isn't preferred)
    chosen_monitor=$((monitor_count - 1))
  fi
  xsetwacom set "${stylus_clean}" MapToOutput HEAD-${chosen_monitor} && \
  echo "-- Mapped to Monitor ${chosen_monitor}"
fi

xsetwacom set "${stylus_clean}" Button 3 "button 3" && \
echo "-- Stylus button 3 set to right-click (button 3)"
xsetwacom set "${stylus_clean}" Button 2 "key Ctrl z" && \
echo "-- Stylus button 2 set to Undo (Ctrl+z)" || \
echo "-- Stylus button 3 failed to set"
xsetwacom set "${pad_clean}" Button 1 "key Ctrl Shift z"
echo "-- Pad button 1 set to Redo (Ctrl+Shift+z)" || \
echo "-- Pad button 1 failed to set"
xsetwacom set "${pad_clean}" Button 2 "key e"
echo "-- Pad button 2 set to Eraser (e)" || \
echo "-- Pad button 2 failed to set"
xsetwacom set "${pad_clean}" Button 3 "key Ctrl s"
echo "-- Pad button 3 set to Save (Ctrl+s)" || \
echo "-- Pad button 3 failed to set"

# UDEV RULE:
## cat /etc/udev/rules.d/99-wacom.rules
## # Match both USB and Bluetooth Wacom Intuos
## ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="056a", ENV{ID_INPUT_TABLET}=="1", TAG+="systemd", ENV{SYSTEMD_USER_WANTS}="wacom-setup.service"
## 
## # Bluetooth Wacom (new)
## ACTION=="add", SUBSYSTEM=="input", ENV{ID_INPUT_TABLET}=="1", ENV{NAME}=="*Wacom Intuos*", TAG+="systemd", ENV{SYSTEMD_USER_WANTS}="wacom-setup.service"

# SystemD script:
## cat /home/<USERNAME>/.config/systemd/user/wacom-setup.service                                
## After=graphical-session.target
## 
## [Service]
## Type=oneshot
## ExecStart=/home/<USERNAME>/path/to/set_draw_pad.sh
## Environment=DISPLAY=:0
## Environment=XAUTHORITY=/home/<USERNAME>/.Xauthority
## 
## [Install]
## WantedBy=default.target

# SETUP
## systemctl --user enable wacom-setup.service
