#!/bin/bash

# Get mouse position
eval $(xdotool getmouselocation --shell)

# Get display information
eval $(xrandr --query | awk 'BEGIN{FS="( | primary |x|+)";screen_num=0};/ connected/ {print "scrn" screen_num "=" $1 ;print "scrn_addr" screen_num "=" $5; screen_num++}')

# Determine which screen the mouse is on
if [[ $X -lt $scrn_addr1 ]]; then
    my_screen="${scrn0}"
elif [[ $X -lt $scrn_addr2 ]]; then
    my_screen="${scrn1}"
else
    my_screen="${scrn2}"
fi

##JHecho "Mouse is on screen: $my_screen"

# Launch the application (replace 'brave-browser' with the actual command)
/etc/alternatives/brave-browser "${1}" &

# Wait for the application to start
sleep 2

# Get the window ID of the most recently opened Brave window
WINDOW_ID=$(wmctrl -l | awk 'BEGIN{found}; /Brave/ {found=$1}; END{print found}')
##JHecho "Window ID: $WINDOW_ID"

# Unmaximize the window
wmctrl -ir $WINDOW_ID -b remove,maximized_vert,maximized_horz

# Move the window to the correct screen
if [[ "$my_screen" == "${scrn0}" ]]; then
    wmctrl -ir $WINDOW_ID -e 0,0,0,-1,-1
elif [[ "$my_screen" == "${scrn1}" ]]; then
    wmctrl -ir $WINDOW_ID -e 0,${scrn_addr1},0,-1,-1
else
    wmctrl -ir $WINDOW_ID -e 0,${scrn_addr2},0,-1,-1
fi

# Maximize the window
wmctrl -ir $WINDOW_ID -b add,maximized_vert,maximized_horz