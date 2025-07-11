#!/bin/bash

## LibreMesh community mesh networks meta-firmware
##
## Copyright (C) 2023-2024  Gioacchino Mazzurco <gio@polymathes.cc>
## Copyright (C) 2023-2024  Asociación Civil Altermundi <info@altermundi.net>
##
## SPDX-License-Identifier: AGPL-3.0-only


## Define default value for variable, take two arguments, $1 variable name,
## $2 default variable value, if the variable is not already define define it
## with default value.
function define_default_value()
{
	VAR_NAME="${1}"
	DEFAULT_VALUE="${2}"

	[ -z "${!VAR_NAME}" ] && export ${VAR_NAME}="${DEFAULT_VALUE}" || true
}


define_default_value OPENWRT_BUILD_DIR "$HOME/Builds/openwrt-apup/"
define_default_value KCONFIG_UTILS_DIR "$HOME/Development/kconfig-utils/"
define_default_value HOSTAPD_REPO_DIR "$HOME/Development/hostap/"
define_default_value OPENWRT_REPO_DIR "$HOME/Development/openwrt/"
define_default_value NETIFD_REPO_DIR "$HOME/Development/netifd/"



cIface="usbe1"

bianco43IP="fe80::c24a:ff:fefc:2f12%$cIface"
bluIP="fe80::6670:2ff:fede:c51e%$cIface"
neroIP="fe80::c24a:ff:fe7a:acac%$cIface"
verdeIP="fe80::ea94:f6ff:fe68:3364%$cIface"

dax1Ipll="fe80::aa63:7dff:fe2e:97c8%$cIface"
dax2Ipll="fe80::aa63:7dff:fe2e:97d8%$cIface"

hlk1Ipll="169.254.145.20"
hlk2Ipll="169.254.145.22"

youhuaIpll="fe80::d65f:25ff:feeb:63d8%$cIface"

source "${KCONFIG_UTILS_DIR}/kconfig-utils.sh"

function fHostapdSourceTreeOverride()
{
	local mHostapdGitSrc="$OPENWRT_BUILD_DIR/package/network/services/hostapd/git-src"
	rm -f "$mHostapdGitSrc"
	ln -s "${HOSTAPD_REPO_DIR}/.git" "$mHostapdGitSrc"
}

function fNetifdSourceTreeOverride()
{
	local mNetifdGitSrc="$OPENWRT_BUILD_DIR/package/network/config/netifd/git-src"
	rm -f "$mNetifdGitSrc"
	ln -s "$NETIFD_REPO_DIR/.git" "$mNetifdGitSrc"
}

function fTestConf()
{
	kconfig_set CONFIG_DEVEL
	kconfig_set CONFIG_SRC_TREE_OVERRIDE

#	fHostapdSourceTreeOverride

	fNetifdSourceTreeOverride

	kconfig_set CONFIG_PACKAGE_iperf3

	kconfig_unset CONFIG_PACKAGE_ppp
	kconfig_unset CONFIG_PACKAGE_ppp-mod-pppoe
	kconfig_unset CONFIG_PACKAGE_kmod-ppp
	kconfig_unset CONFIG_PACKAGE_kmod-pppoe
	kconfig_unset CONFIG_PACKAGE_kmod-pppox
}

function fBuildDapX()
{
	pushd "$OPENWRT_BUILD_DIR"

	./scripts/feeds update -a
	./scripts/feeds install -a

	# Prepare firmware for D-Link DAP-X1860
	echo "" > "$KCONFIG_CONFIG_PATH"
	kconfig_init_register

	kconfig_set CONFIG_TARGET_ramips
	kconfig_set CONFIG_TARGET_ramips_mt7621
	kconfig_set CONFIG_TARGET_ramips_mt7621_DEVICE_dlink_dap-x1860-a1
	make defconfig

	fTestConf
	make defconfig

	kconfig_check
	kconfig_wipe_register

	clean_hostapd

	make -j $(($(nproc)-1))
	popd
}

function fBuildYouhua()
{
	pushd "$OPENWRT_BUILD_DIR"

	./scripts/feeds update -a
	./scripts/feeds install -a

	# Prepare firmware for D-Link DAP-X1860
	echo "" > "$KCONFIG_CONFIG_PATH"
	kconfig_init_register

	kconfig_set CONFIG_TARGET_ramips
	kconfig_set CONFIG_TARGET_ramips_mt7621
	kconfig_set CONFIG_TARGET_ramips_mt7621_DEVICE_youhua_wr1200js
	make defconfig

	fTestConf
	make defconfig

	kconfig_check
	kconfig_wipe_register

	clean_hostapd

	make -j $(($(nproc)-1))
	popd
}

function fBuildHlk()
{
	pushd "$OPENWRT_BUILD_DIR"

	./scripts/feeds update -a
	./scripts/feeds install -a

	# Prepare firmware for D-Link DAP-X1860
	echo "" > "$KCONFIG_CONFIG_PATH"
	kconfig_init_register

	kconfig_set CONFIG_TARGET_ramips
	kconfig_set CONFIG_TARGET_ramips_mt7621
	kconfig_set CONFIG_TARGET_ramips_mt7621_DEVICE_hilink_hlk-7621a-evb
	make defconfig

	kconfig_set CONFIG_PACKAGE_pciutils
	kconfig_set CONFIG_PACKAGE_kmod-mt7916-firmware
	fTestConf
	make defconfig

	kconfig_check
	kconfig_wipe_register

	clean_packages

	make -j $(($(nproc)-1))
	popd
}

function dflash()
{
	dDevice="$1"
	dImage="$2"

	scp -O "${dImage}" root@[${dDevice}]:/tmp/
	imgName="$(basename "$dImage")"

	origHash="$(sha256sum "$dImage" | awk '{print $1}')"
	copiedHash="$(ssh root@$dDevice sha256sum "/tmp/$imgName" | awk '{print $1}')"

	[ "X$origHash" != "X$copiedHash" ] && echo "Hash mismatch" && return -1

	# Do not use -n as this will erease IP confifuration for hilink_hlk-7621a-evb
	ssh root@$dDevice "sysupgrade /tmp/$imgName"

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
#	dWait ${youhuaIpll}
#	dWait ${dax1Ipll}
#	return

#	dWait ${hlk1Ipll}
#	dWait ${hlk2Ipll}
#	return

#	dWait ${dax1Ipll}
#	dWait ${dax2Ipll}
#	return

	dWait ${verdeIP}
#	dWait ${neroIP}
#	dWait ${bluIP}
#	dWait ${bianco43IP}
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
	set wireless.default_radio0.apup='1'
	set wireless.default_radio0.apup_peer_ifname_prefix='wlan0.peer'
	set wireless.default_radio0.network='lan'

	set wireless.radio1.disabled='0'
	set wireless.default_radio1.ssid='libre-curtigghio'
	set wireless.default_radio1.mode='ap'
	set wireless.default_radio1.apup='1'
	set wireless.default_radio1.apup_peer_ifname_prefix='wlan1.peer'
	set wireless.default_radio1.wds_bridge=''
	set wireless.default_radio1.network='lan'

	set firewall.@defaults[0].input='ACCEPT'
	set firewall.@defaults[0].output='ACCEPT'
	set firewall.@defaults[0].forward='ACCEPT'
EOF

	ssh root@${dAddress} uci commit
}

function conf_all()
{
#	dConf ${youhuaIpll} "OpenWrt-Youhua" "192.168.1.24"
#	dConf ${dax1Ipll} "OpenWrt-Dax1" "192.168.1.16"
#	return

#	dConf ${hlk1Ipll} "OpenWrt-Hlk1" "169.254.145.20"
#	dConf ${hlk2Ipll} "OpenWrt-Hlk2" "169.254.145.22"
#	return

#	dConf ${dax1Ipll} "OpenWrt-Dax1" "192.168.1.16"
#	dConf ${dax2Ipll} "OpenWrt-Dax2" "192.168.1.18"
#	return

	dConf ${verdeIP} "OpenWrt-Verde" "192.168.1.4"
#	dConf ${neroIP} "OpenWrt-nero" "192.168.1.10"
#	dConf ${bluIP} "OpenWrt-blu" "192.168.1.8"
#	dConf ${bianco43IP} "OpenWrt-bianco43" "192.168.1.12"
}

function flash_all()
{
#	dflash ${hlk1Ipll} "${OPENWRT_BUILD_DIR}/bin/targets/ramips/mt7621/openwrt-ramips-mt7621-hilink_hlk-7621a-evb-squashfs-sysupgrade.bin"
#	dflash ${hlk2Ipll} "${OPENWRT_BUILD_DIR}/bin/targets/ramips/mt7621/openwrt-ramips-mt7621-hilink_hlk-7621a-evb-squashfs-sysupgrade.bin"

#	dflash ${dax1Ipll} "${OPENWRT_BUILD_DIR}/bin/targets/ramips/mt7621/openwrt-ramips-mt7621-dlink_dap-x1860-a1-squashfs-sysupgrade.bin"
#	dflash ${dax2Ipll} "${OPENWRT_BUILD_DIR}/bin/targets/ramips/mt7621/openwrt-ramips-mt7621-dlink_dap-x1860-a1-squashfs-sysupgrade.bin"

	dflash ${verdeIP} "${OPENWRT_BUILD_DIR}/bin/targets/ath79/generic/openwrt-ath79-generic-tplink_tl-wdr3600-v1-squashfs-sysupgrade.bin"
#	dflash ${neroIP} "${OPENWRT_BUILD_DIR}/bin/targets/ath79/generic/openwrt-ath79-generic-tplink_tl-wdr3600-v1-squashfs-sysupgrade.bin"
#	dflash ${bluIP} "${OPENWRT_BUILD_DIR}/bin/targets/ath79/generic/openwrt-ath79-generic-tplink_tl-wdr3600-v1-squashfs-sysupgrade.bin"
#	dflash ${bianco43IP} "${OPENWRT_BUILD_DIR}/bin/targets/ath79/generic/openwrt-ath79-generic-tplink_tl-wdr4300-v1-squashfs-sysupgrade.bin"

#	dflash ${youhuaIpll} "${OPENWRT_BUILD_DIR}/bin/targets/ramips/mt7621/openwrt-ramips-mt7621-youhua_wr1200js-squashfs-sysupgrade.bin"

	wait_all

	conf_all

#	ssh root@${hlk1Ipll} reboot
#	ssh root@${hlk2Ipll} reboot

#	ssh root@${dax1Ipll} reboot
#	ssh root@${dax2Ipll} reboot

	ssh root@${verdeIP} reboot
#	ssh root@${neroIP} reboot
#	ssh root@${bluIP} reboot
#	ssh root@${bianco43IP} reboot

#	ssh root@${youhuaIpll} reboot
}

function dev_packages_paths()
{
	echo package/feeds/libremesh/lime-system \
	     package/feeds/libremesh/lime-proto-batadv \
	     package/feeds/libremesh/lime-proto-babeld

#	     package/feeds/libremesh/lime-proto-anygw

#	echo package/network/config/netifd
#	     package/network/config/wifi-scripts \
#	     package/network/services/hostapd
}

function clean_packages()
{
	pushd "$OPENWRT_BUILD_DIR"

	for mPackagePath in $(dev_packages_paths) ; do
		make $mPackagePath/clean
	done

	popd
}

function build_packages()
{
	clean_packages

	pushd "$OPENWRT_BUILD_DIR"

	for mPackagePath in $(dev_packages_paths); do
		make $mPackagePath/compile ||
		{
			make $mPackagePath/compile -j1 V=sc
			return -1
		}
	done

	popd
}

function upgrade_packages()
{
	local dAddress="$1"
	local dPkgArch="${2:-mipsel_24kc}"

	local mInstalls=""

	for mPackageName in $(dev_packages_paths) ; do
		mPackageName="$(basename "$mPackageName")"

		local mPkgPath="$(ls "$OPENWRT_BUILD_DIR/bin/packages/$dPkgArch/"*"/$mPackageName"*.ipk | head -n 1)"
		scp -O "$mPkgPath" root@[${dAddress}]:/tmp/

		mInstalls="$mInstalls \"/tmp/$(basename $mPkgPath)\""
	done

	ssh root@${dAddress} "opkg install --force-reinstall $mInstalls && reboot"
}

function upgrade_packages_all()
{
#	upgrade_packages ${hlk1Ipll}
#	upgrade_packages ${hlk2Ipll}

#	upgrade_packages ${dax1Ipll}
#	upgrade_packages ${dax2Ipll}

	upgrade_packages $verdeIP mips_24kc
#	upgrade_packages ${neroIP} mips_24kc
#	upgrade_packages $bluIP mips_24kc
#	upgrade_packages ${bianco43IP} mips_24kc

#	upgrade_packages ${youhuaIpll}

	sleep 5s

	wait_all
}

function errcho() { >&2 echo $@; }

function dTestMulticast()
{
	local dAddress="$1"

	[ "0$(ssh root@${dAddress} ping6 -c 4 ff02::1%phy0-ap0.sta1 | \
		grep duplicates | awk '{print $7}')" -gt "1" ] ||
		{ errcho dTestMulticast $dAddress Failed ; return -1 ; }
	errcho dTestMulticast $dAddress Success
}

function dTestIperf3()
{
	local clientAddress="$1"
	local servAddress="$2"
	local servIfaceAddress="$3"

	ssh root@${servAddress} iperf3 -s
	ssh root@${clientAddress} iperf3 -c $servIfaceAddress
}

function dTestUbusDev()
{
	local dAddress="$1"

#	ssh root@${dAddress} reboot ; sleep 10

#	dWait ${dAddress}

	ssh root@${dAddress} << REMOTE_HOST_EOS
	ubus call network add_dynamic_device '{"name":"wlan0_peer1_47", "type":"8021ad", "ifname":"wlan0.peer1", "vid":"47"}'
	ubus call network add_dynamic '{"name":"wlan0_peer1_47", "proto":"static", "auto":1, "device":"nomestru", "ipaddr":"169.254.145.20", "netmask":"255.255.255.255"}'
	ubus call network.interface.wlan0_peer1_47 up
	ubus call network.device status '{"name":"wlan0_peer1_47"}'

	ip address show wlan0_peer1_47
REMOTE_HOST_EOS
}

function DO_NOT_CALL_prepareHostapdChangesForSubmission()
{
	# Just a bunch of commands I used, not a proper function the commands
	# requires developer interaction
	# See https://openwrt.org/docs/guide-developer/toolchain/use-patches-with-buildsystem

	pushd "$HOSTAPD_REPO_DIR"
	# -3 number of commit for which to create patches
	git format-patch -3 HEAD
	popd

	pushd "$OPENWRT_REPO_DIR"
	make package/network/services/hostapd/{clean,prepare} V=s QUILT=1

	pushd "$OPENWRT_REPO_DIR/build_dir/target-mips_24kc_musl/hostapd-wpad-basic-mbedtls/hostapd-2024.03.09~695277a5"
	quilt push -a

	mLastIndex="$(quilt series | tail -n 1 | awk -F- '{print $1}')"
	for mPatch in $(ls "$HOSTAPD_REPO_DIR"/*.patch) ; do
		mLastIndex=$((mLastIndex+10))
		mNewPatchPath="/tmp/$mLastIndex-$(basename $mPatch | cut -c 6-)"
		mv "$mPatch" "$mNewPatchPath"
		quilt import "$mNewPatchPath"
		quilt push -a
		quilt refresh
		rm "$mNewPatchPath"
	done

	popd

	make package/network/services/hostapd/update V=s
	make package/network/services/hostapd/refresh V=s


	popd
}

#fBuildDapX
#fBuildYouhua

#fBuildHlk

#flash_all

build_packages
upgrade_packages_all

#dTestUbusDev ${youhuaIpll}
#dTestUbusDev ${hlk1Ipll}

#conf_all

#dTestUbusDev ${verdeIP}


#dTestMulticast ${dax1Ipll}
#dTestMulticast ${dax2Ipll}

# dTestMulticast $bluIP
# dTestMulticast $verdeIP
# dTestMulticast $bianco43IP
# dTestMulticast $neroIP
