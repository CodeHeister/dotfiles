#!/bin/bash

print_status() {
    local status artist title
    status=$(playerctl status 2>/dev/null)
    if [[ -z $status ]]; then
        echo ""
        return
    fi
    artist=$(playerctl metadata artist 2>/dev/null)
    title=$(playerctl metadata title 2>/dev/null)
    local label=" ${artist:0:15}$([[ ${#artist} -gt 15 ]] && echo "…") - ${title:0:15}$([[ ${#title} -gt 15 ]] && echo "…")"
    echo "$label"
}

print_status

playerctl --follow metadata --format '{{status}} {{artist}} {{title}}' 2>/dev/null | while read -r line; do
    print_status
done
