#!/bin/sh
# checks for deaf interfaces and brings them up, only if there are associated stations

last_seen_threshold=2000
snr_low_threshold=15

function eui64 {
    mac="$(echo "$1" | tr -d : | tr A-Z a-z)"
    mac="$(echo "$mac" | head -c 6)fffe$(echo "$mac" | tail -c +7)"
    let "b = 0x$(echo "$mac" | head -c 2)"
    let "b ^= 2"
    printf "%02x" "$b"
    echo "$mac" | tail -c +3 | head -c 2
    echo -n :
    echo "$mac" | tail -c +5 | head -c 4
    echo -n :
    echo "$mac" | tail -c +9 | head -c 4
    echo -n :
    echo "$mac" | tail -c +13
}

function sum_all {
    awk '{s+=$1} END {print s}'
}

function get_tx_pkts {
    awk '{print $20}'
}

function get_rx_pkts {
    awk '{print $15}'
}

function filter_unknown {
    grep -v -i unknown
}

function filter_seen {
    awk "{if (int(\$9) < $last_seen_threshold) { print \$0 }}"
}

function filter_snr {
    awk "{if (int(substr(\$8, 0, 2)) > $snr_low_threshold) { print \$0 }}"
}

# sometimes iwinfo skips one MCS, let's remove that info
function filter_MCS_and_Mhz {
    sed -E 's/MCS [0-9]+,\ +[0-9]+MHz//'
}

function four_lines_in_one {
    awk 'ORS=NR%4?" ":"\n"'
}

function get_best_node_on_iface {
    iwinfo $1 a | grep SNR | cut -f1,9 -d\  |tr -d ')' | awk '{print $2,$1}' | sort -n -r | head -1 | awk '{print $2}'
}


function check_and_fix_wifi {
    ping_deadline=3

    for phy in `ls /sys/kernel/debug/ieee80211/`; do
        for iface in `ls /sys/kernel/debug/ieee80211/$phy/ | grep netdev | cut -c 8-`; do
            test_node=`get_best_node_on_iface $iface`

            raw_stations_info=`iwinfo $iface a`
            stations_info=`echo "$raw_stations_info" | filter_MCS_and_Mhz | four_lines_in_one`
            working_station_info=`echo "$stations_info" | grep $test_node`

            num_all_neigh=`echo "$stations_info" | wc -l`

            if [ "$num_all_neigh" -eq "0" ]; then
                logger -t workarounds "deaf_phys: interface $iface has no neighbours, skipping checks."
                continue
            fi

            prev_rx_packet_count=`echo "$working_station_info" | get_rx_pkts`
            prev_tx_packet_count=`echo "$working_station_info" | get_tx_pkts`

            packets_received=$(ping6 -c $((10*$ping_deadline)) -i 0.1 -w $ping_deadline fe80::`eui64 $test_node`%$iface | grep packets\ transmitted | cut -d\  -f4)

            if [[ $packets_received -eq 0 ]]; then
                raw_stations_info=`iwinfo $iface a`
                stations_info=`echo "$raw_stations_info" | filter_MCS_and_Mhz | four_lines_in_one`
                working_station_info=`echo "$stations_info" | grep $test_node`

                if [[ `echo "$working_station_info" | wc -l` -eq 0 ]]; then
                    logger -t workarounds "deaf_phys: interface $iface test neighbour $test_node disconnected before testing, skipping check."
                    continue
                fi

                tx_packet_count=`echo "$working_station_info" | get_tx_pkts`
                rx_packet_count=`echo "$working_station_info" | get_rx_pkts`

                rx_diff=$(( $rx_packet_count - $prev_rx_packet_count ))
                tx_diff=$(( $tx_packet_count - $prev_tx_packet_count ))

                if [[ $tx_diff -eq 0 ]] || [[ $rx_diff -eq 0 ]]; then
                    logger -t workarounds "deaf_phys: $iface ERROR: the interface is deaf. rx $rx_packet_count - $prev_rx_packet_count = $rx_diff tx $tx_packet_count - $prev_tx_packet_count =  $tx_diff. raw values $working_station_info"
                fi
            fi
        done
    done
}

while true; do
    check_and_fix_wifi
    sleep 3
done
