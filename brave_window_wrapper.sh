#!/bin/bash

# Get mouse position
eval $(xdotool getmouselocation --shell)

# Get display information
eval $(xrandr --query | awk 'BEGIN{FS="( | primary |x|+)"};/ connected/ {print $1 "=" $5}')

# Determine which screen the mouse is on
if [[ $X -lt $Virtual2 ]]; then
    my_screen=Virtual1
elif [[ $X -lt $Virtual3 ]]; then
    my_screen=Virtual2
else
    my_screen=Virtual3
fi

##JHecho "Mouse is on screen: $my_screen"

# Launch the application (replace 'brave-browser' with the actual command)
/etc/alternatives/brave-browser "${1}" &

# Wait for the application to start
sleep 2

# Get the window ID of the most recently opened Brave window
WINDOW_ID=$(wmctrl -l | grep "Brave" | tail -1 | awk '{print $1}')
##JHecho "Window ID: $WINDOW_ID"

# Unmaximize the window
wmctrl -ir $WINDOW_ID -b remove,maximized_vert,maximized_horz

# Move the window to the correct screen
if [[ $my_screen == "Virtual1" ]]; then
    wmctrl -ir $WINDOW_ID -e 0,0,0,-1,-1
elif [[ $my_screen == "Virtual2" ]]; then
    wmctrl -ir $WINDOW_ID -e 0,$Virtual2,0,-1,-1
else
    wmctrl -ir $WINDOW_ID -e 0,$Virtual3,0,-1,-1
fi

# Maximize the window
wmctrl -ir $WINDOW_ID -b add,maximized_vert,maximized_horz

