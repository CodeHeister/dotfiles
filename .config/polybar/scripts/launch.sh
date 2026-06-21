#!/bin/bash

killall -q polybar
while pgrep -u $UID -x polybar >/dev/null; do sleep 0.1; done

polybar main 2>&1 | tee /tmp/polybar.log &
wait $!

if [[ $? -eq 0 ]]; then
    notify-send -u low 'Polybar' 'Your statusbar was stopped'
else
    notify-send -u low 'Polybar' 'Something went wrong'
fi
