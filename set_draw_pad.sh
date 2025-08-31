#!/bin/bash
# Runs commands to set up wacom tablet

# How many monitors?
monitor_count=$(xrandr --listmonitors | awk '/Monitors/ {print $2}')

if [[ "${monitor_count}" -gt 1 ]]; then
  xrandr --listmonitors
  read -p "More than one monitor detected. Give me the number for the monitor you want to use: " chosen_monitor
  xsetwacom set "Wacom Intuos BT S Pen stylus" MapToOutput HEAD-${chosen_monitor} && \
  echo "-- Mapped to Monitor ${chosen_monitor}"
fi

xsetwacom set "Wacom Intuos BT S Pen stylus" Button 3 "key Ctrl z" && \
echo "-- Stylus button 3 set to Undo (Ctrl+z)" || \
echo "-- Stylus button 3 failed to set"
xsetwacom set "Wacom Intuos BT S Pad pad" Button 1 "key Ctrl Shift z"
echo "-- Pad button 1 set to Redo (Ctrl+Shift+z)" || \
echo "-- Pad button 1 failed to set"
xsetwacom set "Wacom Intuos BT S Pad pad" Button 2 "key e"
echo "-- Pad button 2 set to Eraser (e)" || \
echo "-- Pad button 2 failed to set"
xsetwacom set "Wacom Intuos BT S Pad pad" Button 3 "key Ctrl s"
echo "-- Pad button 3 set to Save (Ctrl+s)" || \
echo "-- Pad button 3 failed to set"

