#!/bin/sh

#set -x

#ACTIONS are: add prepare clean?
#example: bmx6.sh <action> <virtual_if> <actual_if> <IPv4/16> <IPv6/64>

ACTION=$1
LOGICAL_INTERFACE=$2
REAL_INTERFACE=$3
IPV4=$4
IPV6=$5

clean () {
  uci revert bmx6
  rm /etc/config/bmx6
  touch /etc/config/bmx6
}

prepare () {
  rm -f /etc/config/bmx6
  touch /etc/config/bmx6

  uci set bmx6.general=bmx6
# uci set bmx6.general.ipAutoPrefix="::/0"
# uci set bmx6.general.globalPrefix="fd11::/48"

  # Prevent syslog messages by default
#  uci set bmx6.general.syslog=0

  # Some tunning for the WBM scenario
  uci set bmx6.general.dbgMuteTimeout=1000000
# uci set bmx6.general.purgeTimeout=70000
# uci set bmx6.general.linkPurgeTimeout=20000
# uci set bmx6.general.dadTimeout=15000

  uci set bmx6.tunDev=main
  uci set bmx6.tunDev.tunDev=main
  
  # Enable bmx6 uci config plugin
  uci set bmx6.config=plugin
  uci set bmx6.config.plugin=bmx6_config.so

  # Enable de JSON plugin to get bmx6 information in json format
  uci set bmx6.json=plugin
  uci set bmx6.json.plugin=bmx6_json.so

  # Disable ThrowRules because they are broken in IPv6 with current Linux Kernel
  uci set bmx6.ipVersion=ipVersion
  uci set bmx6.ipVersion.ipVersion=6

  # Search for mesh node's IP
  uci set bmx6.nodes=tunOut
  uci set bmx6.nodes.tunOut=nodes
  uci set bmx6.nodes.network=172.16.0.0/12

  # Search for clouds
  uci set bmx6.clouds=tunOut
  uci set bmx6.clouds.tunOut=clouds
  uci set bmx6.clouds.network=10.0.0.0/8
  
  # Search for internet in the mesh cloud
  uci set bmx6.inet4=tunOut
  uci set bmx6.inet4.tunOut=inet4
  uci set bmx6.inet4.network=0.0.0.0/0
  uci set bmx6.inet4.maxPrefixLen=0

  # Search for internet IPv6 gateways in the mesh cloud
  uci set bmx6.inet6=tunOut
  uci set bmx6.inet6.tunOut=inet6
  uci set bmx6.inet6.network=::/0
  uci set bmx6.inet6.maxPrefixLen=0

  # Search for other mesh cloud announcements
  uci set bmx6.ula=tunOut
  uci set bmx6.ula.tunOut=ula
  uci set bmx6.ula.network=fddf:ca00::/24
  uci set bmx6.ula.minPrefixLen=48

  uci commit bmx6
}

add () {
  uci set bmx6.${LOGICAL_INTERFACE}=dev
  uci set bmx6.${LOGICAL_INTERFACE}.dev=${REAL_INTERFACE}

  # 10.N1.N2.R3/22
  if ! uci -q get bmx6.main.tun4Address > /dev/null ; then
    uci set bmx6.main.tun4Address="$(echo ${IPV4})"
  fi

  if ! uci -q get bmx6.main.tun6Address > /dev/null ; then
    local ipv6=$(echo ${IPV6} | sed "s/\/.*/\/63/")
    uci set bmx6.main.tun6Address="$ipv6"
  fi

  uci commit bmx6
}

stop () {
  killall bmx6
  sleep 2
  killall -9 bmx6
}

start () {
  stop
  bmx6
}

$ACTION
