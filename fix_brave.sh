#!/bin/bash
# This script will unlink /usr/bin/brave-browser from /etc/alternatives/brave-browser
sudo unlink /usr/bin/brave-browser
# And link /usr/bin/brave-browser with /home/jasonhardman/bin/brave_window_wrapper.sh, which calls /etc/alternatives/brave-browser and other things
sudo ln -s /home/jasonhardman/bin/brave_window_wrapper.sh /usr/bin/brave-browser

