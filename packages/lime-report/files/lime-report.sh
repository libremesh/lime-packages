#!/bin/sh

paste_file() {
    echo -ne "\n### FILE $1"
    [ -e "$1" ] && (
        echo -e "\n" &&
        cat "$1" | grep -v key | grep -v pass
    ) || echo -e " NOT FOUND\n"
}

paste_cmd() {
    echo -e "\n### CMD $@\n"
    eval $@ 2>&1 | grep -v key | grep -v pass
}

header() {
    paste_cmd echo hostname $HOSTNAME
    paste_cmd date \'+%Y-%m-%d %H:%M:%S\'
    paste_cmd uptime
}

generate_deviceinfo() {
    paste_file /etc/board.json
    paste_file /proc/cpuinfo
    paste_file /etc/lime_release
    paste_file /etc/openwrt_release
    paste_file /etc/openwrt_version
}

generate_config() {
    paste_file /etc/config/lime-node
    paste_file /etc/config/lime-community
    paste_file /etc/config/lime-defaults
    paste_file /etc/config/lime-autogen
    paste_file /etc/config/network
    paste_file /etc/config/wireless
}

generate_status() {
    paste_cmd dmesg
    paste_cmd batctl if
    paste_cmd batctl o
    paste_cmd bmx6 -c show=status show=interfaces show=links show=originators show=tunnels
    paste_cmd bmx7 -c show=status show=interfaces show=links show=originators show=tunnels
    paste_cmd "echo dump | nc ::1 30003"
    paste_cmd ubus call babeld get_info
    paste_cmd ubus call babeld get_neighbours
    paste_cmd ubus call babeld get_xroutes
    paste_cmd ubus call babeld get_routes
    paste_cmd free
    paste_cmd ps
    paste_cmd ip address show
    paste_cmd ip route show
    paste_cmd brctl show
    paste_cmd ip link show
    paste_cmd df
    paste_cmd logread -l 20
    paste_cmd "logread | grep err"
    paste_cmd iw phy
    paste_cmd iw dev wlan0-mesh station dump
    paste_cmd iw dev wlan1-mesh station dump
    paste_cmd iw dev wlan2-mesh station dump
    paste_cmd iw dev wlan0-mesh mpath dump
    paste_cmd iw dev wlan1-mesh mpath dump
    paste_cmd iw dev wlan2-mesh mpath dump
    paste_cmd iwinfo
    paste_cmd wifi status
    paste_cmd swconfig dev switch0 show
    paste_cmd fw4 print
    paste_cmd nft list ruleset
    paste_cmd opkg list-installed
}

generate_all() {
    generate_deviceinfo
    generate_config
    generate_status
}

[ "$1" = "--help" ] || [ "$1" = "-h" ] && {
    echo "Usage: $0 [OPTION]" && \
    echo "Prints information useful for debugging a LibreMesh network" && \
    echo "-h    for help" && \
    echo "-d    print only device info" && \
    echo "-c    print only main configuration" && \
    echo "-s    print only current status"
}
[ "$1" = "" ] && header && generate_all
[ "$1" = "-d" ] && header && generate_deviceinfo
[ "$1" = "-c" ] && header && generate_config
[ "$1" = "-s" ] && header && generate_status
