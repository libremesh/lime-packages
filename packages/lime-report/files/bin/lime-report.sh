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

generate_shared_state() {
    echo -e "\n### shared-state-async registered datatypes\n"
    for section in $(uci show shared-state 2>/dev/null | grep '=dataType' | cut -d'.' -f2 | cut -d'=' -f1); do
        datatype=$(uci -q get shared-state.$section.name)
        if [ -n "$datatype" ]; then
            echo -e "\n### CMD shared-state-async dump $datatype\n"
            shared-state-async dump "$datatype" 2>&1
        fi
    done

    paste_file /tmp/shared-state/shared-state-async.conf
    paste_file /tmp/shared-state-get_candidates_neigh.cache
    paste_file /tmp/shared-state-get_candidates_neigh.lastrun

    echo -e "\n### Old shared-state data files\n"
    for datafile in /var/shared-state/data/*.json ; do
        [ -e "$datafile" ] && paste_file "$datafile"
    done

    echo -e "\n### Persistent shared-state-multiwriter data\n"
    for datafile in /etc/shared-state/persistent-data/*.json ; do
        [ -e "$datafile" ] && paste_file "$datafile"
    done

    paste_file /etc/config/shared-state
}

generate_all() {
    generate_deviceinfo
    generate_config
    generate_status
    generate_shared_state
}

[ "$1" = "--help" ] || [ "$1" = "-h" ] && {
    echo "Usage: $0 [OPTION]" && \
    echo "Prints information useful for debugging a LibreMesh network" && \
    echo "-h    for help" && \
    echo "-d    print only device info" && \
    echo "-c    print only main configuration" && \
    echo "-s    print only current status" && \
    echo "-ss   print only shared-state-async data (publish all and dump all datatypes)"
}
[ "$1" = "" ] && header && generate_all
[ "$1" = "-d" ] && header && generate_deviceinfo
[ "$1" = "-c" ] && header && generate_config
[ "$1" = "-s" ] && header && generate_status
[ "$1" = "-ss" ] && header && generate_shared_state
