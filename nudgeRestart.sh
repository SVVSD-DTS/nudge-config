#!/bin/bash

###
#
#                    Author : La Clémentine · https://medium.com/@laclementine/
#				 Updated by : Edward Lewis · lewis_edward@svvsd.org
#                   Created : 2023-09-03
#             Last Modified : 2023-10-24
#                   Version : 1.1
#               Tested with : macOS 14.0
#
###

# Kill pending Dialog
killall Dialog

# Get current user
CURRENT_USER=$(stat -f %Su /dev/console)
USER_ID=$(id -u "$CURRENT_USER")

# Time logic by Pico : https://github.com/PicoMitchell
# Determine current Unix epoch time
current_unix_time="$(date '+%s')"

# This reports the unix epoch time that the kernel was booted
boot_unix_time="$(sysctl -n kern.boottime | awk -F 'sec = |, usec' '{ print $2; exit }')"

# Get uptime in seconds by doing maths
uptime_seconds="$(( current_unix_time - boot_unix_time ))"

# Calculate uptime in days
uptime_minutes="$(( uptime_seconds / 60 ))"
uptime_hours="$(( uptime_minutes / 60 ))"
uptime_days="$(( uptime_hours / 24 ))"

# Hardcoded uptime for testing on your own computer.
# uptime_days="28"

if [ "$uptime_days" -le 6 ]; then
 echo "Uptime less than or equal to 6 days. Exit."
 exit 0

elif [ "$uptime_days" -ge 7 ] && [ "$uptime_days" -le 10 ]; then
 echo "Uptime between 7 and 10 days. Notification."
 launchctl asuser "$USER_ID" sudo -u "$CURRENT_USER" /usr/local/bin/dialog \
 --notification \
 --title "$uptime_days days without a restart!" \
 --message "Your Mac needs to restart so it can regain its original performance. Important security updates may also be installed during the process."
 # afplay "/System/Library/Sounds/Sosumi.aiff"
 exit 0

elif [ "$uptime_days" -ge 11 ] && [ "$uptime_days" -le 13 ]; then
 echo "Uptime between 11 and 13 days. Dialog."
 # afplay "/System/Library/Sounds/Sosumi.aiff" &
 launchctl asuser "$USER_ID" sudo -u "$CURRENT_USER" /usr/local/bin/dialog \
 --title "Restart required" \
 --message "**${uptime_days} days without a restart!** \n\nYour Mac needs to restart so it can regain its original performance. Important security updates may also be installed during the process. Please save your work and press Restart. If you press Defer, you'll be reminded again in 24 hours.\n\nPlease note that if the timer reaches zero, your computer will be automatically restarted. Thank you for your cooperation." \
 --icon "https://sw-dist.svvsd.org/v1/icons/vrainstorm-512.png" \
 --button1text "Restart now" \
 --button2text "Defer" \
 --timer 840 \
 --width 650 --height 280 \
 --messagefont size=13 \
 --position bottomright \
 --moveable \
 --ontop
 dialogResults=$?

elif [ "$uptime_days" -ge 14 ]; then
 echo "Uptime greater than 14 days. Last warning dialog."
 # Commented out turning sound on and alert
 # osascript -e "set volume output volume 80 --100%"
 # afplay "/System/Library/Sounds/Sosumi.aiff" & sleep 0.2 && afplay "/System/Library/Sounds/Sosumi.aiff" & sleep 0.4 && afplay "/System/Library/Sounds/Sosumi.aiff" &

 launchctl asuser "$USER_ID" sudo -u "$CURRENT_USER" /usr/local/bin/dialog \
 --title "Restart required" \
 --message "**${uptime_days} days without a restart!** \n\nYour Mac needs to restart so it can regain its original performance. Important security updates may also be installed during the process.\n\nAfter pressing **I understand**, you will have 10 minutes to restart your computer." \
 --icon "https://sw-dist.svvsd.org/v1/icons/vrainstorm-512.png" \
 --button1text "I understand" \
 --width 650 --height 230 \
 --messagefont size=13 \
 --hidetimerbar \
 --blurscreen \
 --ontop

 launchctl asuser "$USER_ID" sudo -u "$CURRENT_USER" /usr/local/bin/dialog \
 --title none \
 --message "Your computer will restart when the timer reaches zero. Please save your work now." \
 --button1text "Restart now" \
 --timer 600 \
 --width 320 --height 110 \
 --messagefont size=13 \
 --position bottomright \
 --icon none \
 --ontop
 dialogResults=$?
fi

if [ "$dialogResults" = "0" ]; then
 # Button pressed. Graceful restart. Unsaved documents will stop the process.
 echo "Restart pressed"
 osascript -e 'tell application "Finder"
 restart
 end tell'
 # If the computer hasn't restarted after 15 seconds, force a restart.
 sleep 15
 shutdown -r now
elif [ "$dialogResults" = "2" ]; then
 # Dialog canceled.
 echo "Defer pressed"
elif [ "$dialogResults" = "4" ]; then
 # Timer expired. Graceful restart only.
 echo "Timer expired, restarting now"
 osascript -e 'tell application "Finder"
 restart
 end tell'
else
 echo "${uptime_days}"
 echo "Could be an error in the dialog command"
 echo "Could be the process killed somehow."
 echo "Exit with an error code."
 exit "$dialogResults"
fi
