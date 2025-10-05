#!/bin/bash

# Kill any existing polybar instances
killall -q polybar

# Wait for processes to be killed
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Get primary monitor first
primary_monitor=$(xrandr --query | grep ' connected primary' | cut -d' ' -f1)

# Launch polybar on primary monitor first
if [ ! -z "$primary_monitor" ]; then
    echo "Starting polybar on primary monitor: $primary_monitor"
    MONITOR=$primary_monitor polybar --reload mybar &
    sleep 0.5
fi

# Launch polybar for remaining monitors
for monitor in $(xrandr --query | grep ' connected' | cut -d' ' -f1); do
    if [ "$monitor" != "$primary_monitor" ]; then
        echo "Starting polybar on monitor: $monitor"
        MONITOR=$monitor polybar --reload mybar &
        sleep 0.5
    fi
done

echo "Polybar launched on all monitors"