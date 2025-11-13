#!/usr/bin/env sh

# Terminate already running polybar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -x polybar >/dev/null; do sleep 1; done

# Launch Polybar
# You might need to specify your bar name, e.g., "mybar"
polybar 
