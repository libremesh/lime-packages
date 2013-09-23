#!/bin/sh
#    Copyright (C) 2011 Fundacio Privada per a la Xarxa Oberta, Lliure i Neutral guifi.net
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License along
#    with this program; if not, write to the Free Software Foundation, Inc.,
#    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
#    The full GNU General Public License is included in this distribution in
#    the file called "COPYING".
#
# Contributors: Pau Escrich <p4u@dabax.net>
#

#Uncomment this line to debut
#DEBUG="/tmp/qmp_common.debug"

#######################
# UCI related commands
#######################

wbm_uci_get() {
	u="$(uci -q get $@)"
	r=$?
	echo "$u"
	[ $r -ne 0 ] && logger -t wbm "UCI returned an error (uci get wbm.$1)"
	wbm_debug "wbm_uci_get: uci -q get wbm.$1"
	return $r
}

wbm_uci_set_() {
	uci -q set $@ > /dev/null
	r=$?
	uci commit
	r=$(( $r + $? ))
	[ $r -ne 0 ] && logger -t wbm "UCI returned an error (uci set $@)"
	wbm_debug "wbm_uci_set: uci -q set $@"
        return $r
}

wbm_uci_del() {
        uci -q del $@
	r=$?
	uci commit
	r=$(( $r + $? ))
	[ $r -ne 0 ] && logger -t wbm "UCI returned an error (uci del $@)"
	wbm_debug "wbm_uci_del uci -q del $@"
	return $r
}

wbm_uci_add() {
	uci -q add $@ > /dev/null
	r=$?
	uci commit
	r=$(( $r + $? ))
	[ $r -ne 0 ] && logger -t wbm "UCI returned an error (uci add wbm $1)"
	wbm_debug "wbm_uci_add: uci -q add wbm $1"
	return $r
}

wbm_uci_add_get_cfg() {
	cfg=$(uci -q add $@)
	r=$?
	[ $r -ne 0 ] && logger -t wbm "UCI returned an error (uci add $@)"
	echo "$cfg"
	wbm_debug "wbm_uci_add_get_cfg: uci -q add $@"
	return $r
}

wbm_uci_set_cfg() {
	uci -q set $@ >/dev/null
	wbm_debug "wbm_uci_set_cfg: uci -q set $@"
	return $?
}

wbm_uci_commit() {
	uci commit $1
	r=$(( $r + $? ))
	[ $r -ne 0 ] && logger -t wbm "UCI returned an error (uci commit $1)"
	wbm_debug "wbm_uci_commit: uci commit $1"
	return $r
}

wbm_uci_add_list() {
	uci -q add_list $@ > /dev/null
	r=$?
	uci commit
	r=$(( $r + $? ))
	[ $r -ne 0 ] && logger -t wbm "UCI returned an error (uci add_list $@)"
	wbm_debug "wbm_uci_add_list: uci -q add_list $@"
	return $r
}

wbm_uci_import() {
	cat "$1" | while read v; do
	[ ! -z "$v" ] && { uci set $v; wbm_debug "wbm_uci_import: uci set $v"; }
	done
	uci commit
	return $?
}

wbm_uci_test() {
	option=$1
	u="$(uci get $@ > /dev/null 2>&1)"
	r=$?
	return $r
}

##################################
# Log and errors related commnads
##################################

# Exit from execution and shows an error
# wbm_error The device is burning
wbm_error() {
	logger -s -t wbm "ERROR: $@"
	exit 1
}

# Send info to system log
# wbm_log wbm is the best
wbm_log() {
	logger -s -t wbm "$@"
}

wbm_debug() {
	[ ! -z "$DEBUG" ] &&  echo "$@" >> $DEBUG
}

#######################################
# Networking and Wifi related commands
#######################################

# Returns the names of the wifi devices from the system
wbm_get_wifi_devices() {
	echo "$(ip link | grep  -E ": (wifi|wlan).: "| cut -d: -f2)"
}

# Returns the MAC address of the wifi devices
wbm_get_wifi_mac_devices() {
	echo "$(ip link | grep -A1 -E ": (wifi|wlan).: " | grep link | cut -d' ' -f6)"
}

# Returns the device name that corresponds to the MAC address
# wbm_get_dev_from_mac 00:22:11:33:44:55
wbm_get_dev_from_mac() {
	echo "$(ip link | grep $1 -i -B1 | grep -v \@ | egrep -v "ether|br|mon" | grep mtu | awk '{print $2}' | tr -d : | awk NR==1)"
}

# Returns the mac address of the device
# wbm_get_mac_for_dev eth0
wbm_get_mac_for_dev() {
    mac="$(ip link show dev $1 | grep -m 1 "link/ether" | awk '{print $2}')"
	[ -z "$mac" ] && mac="00:00:00:00:00:00"
	echo "$mac"
}

#########################
# Other kind of commands
#########################

# Print the content of the parameters in reverse order (separed by spaces)
wbm_reverse_order() {
	echo "$@" | awk '{for (i=NF; i>0; i--) printf("%s ",$i);print ""}'
}

# Print the output of the command parameter in reverse order (separed by lines)
wbm_tac() {
	$@ | awk '{a[NR]=$0} END {for(i=NR;i>0;i--)print a[i]}'
}

# Returns the prefix /XX from netmask
wbm_get_prefix_from_netmask() {
 echo "$(ipcalc.sh 1.1.1.1 $1| grep PREFIX | cut -d= -f2)"
}

# Returns the netid from IP NETMASK
wbm_get_netid_from_network() {
 echo "$(ipcalc.sh $1 $2 | grep NETWORK | cut -d= -f2)"
}

