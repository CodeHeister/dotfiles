#!/bin/bash
# Polybar custom workspaces with per-ws colors

ws_color=(
    "#52E080"
    "#DA1212"
    "#117dca"
    "#32a7d9"
    "#23cf5f"
    "#B3541E"
    "#FFC600"
    "#A267AC"
    "#B33030"
    "#F5F5F5"
)
ws_color_len=${#ws_color[@]}

get_workspaces() {
    local out=""
    local ws_json
    ws_json=$(i3-msg -t get_workspaces 2>/dev/null)
    local count
    count=$(echo "$ws_json" | jq 'length')

    for (( i=0; i<count; i++ )); do
        local num name visible urgent color icon
        num=$(echo "$ws_json"     | jq -r ".[$i].num")
        name=$(echo "$ws_json"    | jq -r ".[$i].name")
        visible=$(echo "$ws_json" | jq -r ".[$i].visible")
        urgent=$(echo "$ws_json"  | jq -r ".[$i].urgent")

        # Last character of name = icon
        icon="${name: -1}"

        # Color by num
        local idx=$(( num - 1 ))
        if (( idx >= 0 && idx < ws_color_len )); then
            color="${ws_color[$idx]}"
        else
            color="#abb2bf"
        fi

		if [[ $urgent == "true" ]]; then
			out+="%{A1:i3-msg workspace number $num:}%{B#aadc322f}%{F#282c34} $icon %{F-}%{B-}%{A}"
		elif [[ $visible == "true" ]]; then
			out+="%{A1:i3-msg workspace number $num:}%{B#554b5263}%{F$color}%{o$color}%{+o} $icon %{-o}%{F-}%{B-}%{A}"
		else
			out+="%{A1:i3-msg workspace number $num:}%{F#abb2bf} $icon %{F-}%{A}"
		fi
    done

    echo -n "$out"
}

while true; do
    get_workspaces
    echo ""
    i3-msg -t subscribe -m '["workspace", "output"]' 2>/dev/null | while read -r _; do
        get_workspaces
        echo ""
    done
done
