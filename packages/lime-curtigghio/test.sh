#!/bin/bash

## LibreMesh community mesh networks meta-firmware
##
## Copyright (C) 2023  Gioacchino Mazzurco <gio@eigenlab.org>
## Copyright (C) 2023  Asociación Civil Altermundi <info@altermundi.net>
##
## SPDX-License-Identifier: AGPL-3.0-only

mBuildDir="/home/gio/Builds/openwrt"

cIface="em0"

bianco43IP="fe80::c24a:ff:fefc:2f12%$cIface"
bluIP="fe80::6670:2ff:fede:c51e%$cIface"
neroIP="fe80::c24a:ff:fe7a:acac%$cIface"
verdeIP="fe80::ea94:f6ff:fe68:3364%$cIface"


function dflash()
{
	dDevice="$1"
	dImage="$2"

	scp -O "${dImage}" root@[${dDevice}]:/tmp/
	imgName="$(basename "$dImage")"

	origHash="$(sha256sum "$dImage" | awk '{print $1}')"
	copiedHash="$(ssh root@$dDevice sha256sum "/tmp/$imgName" | awk '{print $1}')"

	[ "X$origHash" != "X$copiedHash" ] && echo "Hash mismatch" && return -1

	ssh root@$dDevice "sysupgrade -n /tmp/$imgName"

	# Wait the detached flashing to start
	sleep 10
}

# Wait for a device to be ready after flashing
function dWait()
{
	dAddress="$1"
	mInterval="10s"
	mTryMax="20"

	function mTest()
	{
		dUptime="$(ssh root@$dAddress cat /proc/uptime)"
		[ "0$(echo $dUptime | awk -F. '{print $1}')" -gt "100" ]
	}

	for mTry in $(seq $mTryMax -1 1) ; do
		mTest && return $? || sleep $mInterval $mTry
	done

	# Failure after max try
	return -1
}

function wait_all()
{
	dWait ${verdeIP}
	dWait ${neroIP}
	dWait ${bluIP}
	dWait ${bianco43IP}
}

function dConf()
{
	dAddress="$1"
	dHostName="$2"
	dHostIPv4="$3"

	cat << EOF | ssh root@${dAddress} uci batch

	set system.@system[0].hostname="$dHostName"
	set network.lan.ipaddr="$dHostIPv4"

	set dhcp.lan.ignore='1'

	set network.curtigghio=interface
	set network.curtigghio.proto='none'
	set network.curtigghio.auto='1'

	set wireless.radio0.disabled='0'
	set wireless.radio0.channel='9'
	set wireless.default_radio0.ssid='libre-curtigghio'
	set wireless.default_radio0.mode='ap'
	set wireless.default_radio0.wds='1'
	set wireless.default_radio0.network='curtigghio'

	set wireless.radio1.disabled='0'
	set wireless.default_radio1.ssid='libre-curtigghio'
	set wireless.default_radio1.mode='ap'
	set wireless.default_radio1.wds='1'
	set wireless.default_radio1.network='curtigghio'

	set firewall.@defaults[0].input='ACCEPT'
	set firewall.@defaults[0].output='ACCEPT'
	set firewall.@defaults[0].forward='ACCEPT'
EOF

	ssh root@${dAddress} uci commit
}

function conf_all()
{
	dConf ${verdeIP} "OpenWrt-Verde" "192.168.1.4"
	dConf ${neroIP} "OpenWrt-nero" "192.168.1.10"
	dConf ${bluIP} "OpenWrt-blu" "192.168.1.8"
	dConf ${bianco43IP} "OpenWrt-bianco43" "192.168.1.12"
}

function flash_all()
{
	dflash ${verdeIP} "${mBuildDir}/bin/targets/ath79/generic/openwrt-ath79-generic-tplink_tl-wdr3600-v1-squashfs-sysupgrade.bin"
	dflash ${neroIP} "${mBuildDir}/bin/targets/ath79/generic/openwrt-ath79-generic-tplink_tl-wdr3600-v1-squashfs-sysupgrade.bin"
	dflash ${bluIP} "${mBuildDir}/bin/targets/ath79/generic/openwrt-ath79-generic-tplink_tl-wdr3600-v1-squashfs-sysupgrade.bin"
	dflash ${bianco43IP} "${mBuildDir}/bin/targets/ath79/generic/openwrt-ath79-generic-tplink_tl-wdr4300-v1-squashfs-sysupgrade.bin"

	wait_all

	conf_all

	ssh root@${verdeIP} reboot
	ssh root@${neroIP} reboot
	ssh root@${bluIP} reboot
	ssh root@${bianco43IP} reboot
}

function build_hostapd()
{
	pushd "$mBuildDir"

	make package/network/services/hostapd/clean
	make package/network/services/hostapd/compile || 
		make package/network/services/hostapd/compile -j1 V=s

	popd
}

function upgrade_hostapd()
{
	dAddress="$1"
	mHostapdPkgPath="$(ls $mBuildDir/bin/packages/mips_24kc/base/wpad-basic-*.ipk)"

	scp -O "$mHostapdPkgPath" root@[${dAddress}]:/tmp/

	ssh root@${dAddress} "opkg install --force-reinstall \"/tmp/$(basename $mHostapdPkgPath)\" && reboot"
}

function upgrade_hostapd_all()
{
	upgrade_hostapd $verdeIP
	upgrade_hostapd ${neroIP}
	upgrade_hostapd $bluIP
	upgrade_hostapd ${bianco43IP}

	sleep 5s

	wait_all
}

function errcho() { >&2 echo $@; }

function dTestMulticast()
{
	dAddress="$1"

	[ "0$(ssh root@${dAddress} ping6 -c 4 ff02::1%phy0-ap0.sta1 | \
		grep duplicates | awk '{print $7}')" -gt "1" ] ||
		{ errcho dTestMulticast $1 Failed ; return -1 ; }
	errcho dTestMulticast $1 Success
}

#flash_all
#conf_all

build_hostapd
conf_all
upgrade_hostapd_all

dTestMulticast $bluIP
dTestMulticast $verdeIP
dTestMulticast $bianco43IP
dTestMulticast $neroIP

