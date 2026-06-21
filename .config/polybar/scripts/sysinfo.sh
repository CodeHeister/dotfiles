#!/bin/bash
# cpu, ram, volume, network, layout — show value on change, hide after delay
# click on cpu/ram/net/layout forces a temporary show too
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
POPUP_DELAY=3
POPUP_CPU=7
fg="#abb2bf"
red="#FF0800"
yellow="#FFC40C"
cpu_icon=""
ram_icon=""
net_icon=""
lay_icon=""
vol_mute=""
vol_low=""
vol_hi=""
last_cpu=0
last_ram=""
last_vol=""
last_net=""
last_lay=""
cpu_timer=0
ram_timer=0
vol_timer=0
net_timer=0
lay_timer=0
sound_toggle="pactl set-sink-mute @DEFAULT_SINK@ toggle"
sound_up="pactl set-sink-volume @DEFAULT_SINK@ +5%"
sound_down="pactl set-sink-volume @DEFAULT_SINK@ -5%"

# flag files used by click actions to request a forced "show"
FLAG_DIR="/tmp/polybar-flags-$$"
mkdir -p "$FLAG_DIR"
CPU_FLAG="$FLAG_DIR/cpu"
RAM_FLAG="$FLAG_DIR/ram"
NET_FLAG="$FLAG_DIR/net"
LAY_FLAG="$FLAG_DIR/lay"
LAY_FIFO="$FLAG_DIR/layfifo"

force_cpu="touch $CPU_FLAG"
force_ram="touch $RAM_FLAG"
force_net="touch $NET_FLAG"
force_lay="touch $LAY_FLAG"

# запускаем watcher раскладки в фоне и читаем из него через FIFO
mkfifo "$LAY_FIFO"
"$SCRIPT_DIR/getxkblayout" -w > "$LAY_FIFO" 2>/dev/null &
XKBWATCH_PID=$!
exec 3<"$LAY_FIFO"

cleanup() {
    kill "$XKBWATCH_PID" 2>/dev/null
    exec 3<&-
    rm -rf "$FLAG_DIR"
}
trap cleanup EXIT

get_cpu() {
    awk '{u=$2+$4; t=$2+$4+$5; if(NR==1){u1=u;t1=t;} else printf "%.0f", (u-u1)*100/(t-t1)}' \
        <(grep 'cpu ' /proc/stat) <(sleep 0.2; grep 'cpu ' /proc/stat)
}
get_ram() {
    free | awk 'NR==2 {printf "%.0f", $3/$2*100}'
}
get_vol() {
    local sink vol mute
    sink=$(pactl info 2>/dev/null | awk '/Default Sink/{print $3}')
    vol=$(pactl list sinks 2>/dev/null | grep -A 15 "$sink" | awk '/Volume:/{print $5; exit}' | tr -d '%')
    mute=$(pactl list sinks 2>/dev/null | grep -A 15 "$sink" | awk '/Mute:/{print $2; exit}')
    echo "${vol:-0} ${mute:-no}"
}
get_net() {
    ip route get 8.8.8.8 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="dev") print $(i+1)}'
}
format_cpu() {
    local val=$1
    if (( val >= 70 )); then
        echo "%{F$red}$cpu_icon $val%%%{F-}"
    elif (( val >= 40 )); then
        echo "%{F$yellow}$cpu_icon $val%%%{F-}"
    else
        echo "$cpu_icon $val%"
    fi
}
format_ram() {
    local val=$1
    if (( val >= 60 )); then
        echo "%{F$red}$ram_icon $val%%%{F-}"
    elif (( val >= 40 )); then
        echo "%{F$yellow}$ram_icon $val%%%{F-}"
    else
        echo "$ram_icon $val%"
    fi
}
format_vol() {
    local val=$1 mute=$2 icon
    if [[ $mute == "yes" ]]; then
        echo "%{F$yellow}$vol_mute muted%{F-}"
        return
    fi
    if   (( val == 0 ));  then icon="$vol_mute"
    elif (( val <= 50 )); then icon="$vol_low"
    else                       icon="$vol_hi"
    fi
    echo "$icon $val%"
}
format_vol_icon() {
    local val=$1 mute=$2
    if [[ $mute == "yes" ]]; then
        echo "%{F$yellow}$vol_mute%{F-}"
        return
    fi
    if   (( val == 0 ));  then echo "$vol_mute"
    elif (( val <= 50 )); then echo "$vol_low"
    else                       echo "$vol_hi"
    fi
}
format_net() {
    local ip=$1
    if [[ -z $ip ]]; then
        echo "%{F$red}$net_icon%{F-}"
    else
        echo "$net_icon $ip"
    fi
}
format_lay() {
    local lay=$1
    if [[ -z $lay ]]; then
        echo "%{F$red}$lay_icon%{F-}"
    else
        echo "$lay_icon $lay"
    fi
}
# Init
cpu_out="$cpu_icon"
ram_out="$ram_icon"
read -r init_vol init_mute <<< "$(get_vol)"
vol_out="$(format_vol_icon "$init_vol" "$init_mute")"
last_vol="$init_vol $init_mute"
net_out="$net_icon"
last_net=""
lay_out="$lay_icon"
last_lay=""
print_bar() {
    local sep="  "
    echo "%{A1:$force_net:}$net_out%{A}$sep%{A1:$force_cpu:}$cpu_out%{A}$sep%{A1:$force_ram:}$ram_out%{A}$sep%{A1:$force_lay:}$lay_out%{A}$sep%{A1:$sound_toggle:}%{A4:$sound_up:}%{A5:$sound_down:}$vol_out%{A}%{A}%{A}"
}
print_bar
while true; do
    now=$(date +%s)

    # check click-force flags
    cpu_force=0
    ram_force=0
    net_force=0
    lay_force=0
    if [[ -e $CPU_FLAG ]]; then cpu_force=1; rm -f "$CPU_FLAG"; fi
    if [[ -e $RAM_FLAG ]]; then ram_force=1; rm -f "$RAM_FLAG"; fi
    if [[ -e $NET_FLAG ]]; then net_force=1; rm -f "$NET_FLAG"; fi
    if [[ -e $LAY_FLAG ]]; then lay_force=1; rm -f "$LAY_FLAG"; fi

    # CPU
    cpu=$(get_cpu)
    if (( cpu - last_cpu >= POPUP_CPU || last_cpu - cpu >= POPUP_CPU || cpu_force == 1 )); then
        cpu_out="$(format_cpu "$cpu")"
        cpu_timer=$(( now + POPUP_DELAY ))
        last_cpu=$cpu
    elif (( now > cpu_timer )); then
        cpu_out="$cpu_icon"
    fi
    # RAM
    ram=$(get_ram)
    if [[ $ram != $last_ram || $ram_force == 1 ]]; then
        ram_out="$(format_ram "$ram")"
        ram_timer=$(( now + POPUP_DELAY ))
        last_ram=$ram
    elif (( now > ram_timer )); then
        ram_out="$ram_icon"
    fi
    # Volume
    read -r vol mute <<< "$(get_vol)"
    vol_key="$vol $mute"
    if [[ $vol_key != $last_vol ]]; then
        vol_out="$(format_vol "$vol" "$mute")"
        vol_timer=$(( now + POPUP_DELAY ))
        last_vol=$vol_key
    elif (( now > vol_timer )); then
        vol_out="$(format_vol_icon "$vol" "$mute")"
    fi
    # Network
    net=$(get_net)
    if [[ $net != $last_net || $net_force == 1 ]]; then
        net_out="$(format_net "$net")"
        net_timer=$(( now + POPUP_DELAY ))
        last_net=$net
    elif (( now > net_timer )); then
        net_out="$net_icon"
    fi
    # Layout — событие приходит из getxkblayout -w через FIFO, без поллинга
    if read -t 0 -u 3 new_lay 2>/dev/null; then
        last_lay_changed=1
    else
        new_lay="$last_lay"
        last_lay_changed=0
    fi
    if [[ $last_lay_changed == 1 || $lay_force == 1 ]]; then
        lay_out="$(format_lay "$new_lay")"
        lay_timer=$(( now + POPUP_DELAY ))
        last_lay="$new_lay"
    elif (( now > lay_timer )); then
        lay_out="$lay_icon"
    fi

    print_bar
    sleep 0.5
done
