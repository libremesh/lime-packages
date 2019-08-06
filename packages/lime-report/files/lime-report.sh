#!/bin/sh

export PASTE_SERVICE="http://paste.libremesh.org"
export PASTE_PORT="8080"

paste_file() {
    echo -n "\n### FILE $1"
    [ -e "$1" ] && (
        echo "\n" &&
        cat "$1" | grep -v key | grep -v pass
    ) || echo -e " NOT FOUND\n"
}

paste_cmd() {
    echo -e "\n### CMD $@\n"
    eval $@ 2>&1
}

generate() {
    paste_file /etc/config/lime
    paste_file /etc/config/lime-defaults
    paste_file /etc/config/network
    paste_file /etc/config/wireless
    paste_cmd dmesg | tail -c 10
    paste_cmd batctl if
    paste_cmd batctl o
    paste_cmd bmx6 -c show=status show=interfaces show=links show=originators show=tunnels
    paste_cmd bmx7 -c show=status show=interfaces show=links show=originators show=tunnels
    paste_cmd free
    paste_cmd ps
    paste_cmd ip address show
    paste_cmd ip route show
    paste_cmd brctl show
    paste_cmd ip link show
    paste_file /proc/cpuinfo
    paste_cmd df
    paste_cmd logread -l 20
    paste_cmd iw dev wlan0-mesh station dump
    paste_cmd iw dev wlan1-mesh station dump
    paste_cmd iw dev wlan0-mesh mpath dump
    paste_cmd iw dev wlan1-mesh mpath dump
    paste_cmd iwinfo
}

[ "$1" = "" ] || [ "$1" = "-h" ] && {
    echo "-h    for help" && \
    echo "-p    paste to $PASTE_SERVICE" && \
    echo "-f    store in /tmp/<date_time>.txt" && \
    echo "-o    print in stdout" 
} 
[ "$1" = "-o" ] && generate
[ "$1" = "-p" ] && generate | lime-paste
[ "$1" = "-f" ] && { 
    REPORT_FILE="/tmp/lime-paste_$(date '+%Y-%m-%d_%H%M%S').txt"
    generate > "$REPORT_FILE"
    echo "stored in $REPORT_FILE"
}
