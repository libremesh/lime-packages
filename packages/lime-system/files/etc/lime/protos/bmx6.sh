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

  # Enable bmx6 uci config plugin
  uci set bmx6.config=plugin
  uci set bmx6.config.plugin=bmx6_config.so

  # Enable de JSON plugin to get bmx6 information in json format
#  uci set bmx6.json=plugin
#  uci set bmx6.json.plugin=bmx6_json.so

  # Disable ThrowRules because they are broken in IPv6 with current Linux Kernel
  uci set bmx6.ipVersion=ipVersion
  uci set bmx6.ipVersion.ipVersion=6
  uci set bmx6.ipVersion.throwRules=0


  # Smart gateway search for IPV4

  # Search for any announcement of 10/8 in the mesh cloud
  #uci set bmx6.mesh=tunOut
  #uci set bmx6.mesh.tunOut=mesh
  #uci set bmx6.mesh.network=10.0.0.0/8
  #uci set bmx6.mesh.minPrefixLen=24
  #uci set bmx6.mesh.maxPrefixLen=32

  # Search for internet in the mesh cloud
  #uci set bmx6.inet=tunOut
  #uci set bmx6.inet.tunOut=inet
  #uci set bmx6.inet.network=0.0.0.0/0
  #uci set bmx6.inet.minPrefixLen=0
  #uci set bmx6.inet.maxPrefixLen=0


# Smart gateway search for IPV6
  
  # Search for internet IPv6 gateways in the mesh cloud
  uci set bmx6.gw_v6=tunOut
  uci set bmx6.gw_v6.tunOut=gw_v6
  uci set bmx6.gw_v6.network=::/0
  uci set bmx6.gw_v6.maxPrefixLen=0

  # Search for other mesh cloud announcements
  uci set bmx6.lime_ula=tunOut
  uci set bmx6.lime_ula.tunOut=lime_ula
  uci set bmx6.lime_ula.network=fddf:ca00::/24
  uci set bmx6.lime_ula.minPrefixLen=48

  uci commit bmx6
}

add () {
  uci set bmx6.${LOGICAL_INTERFACE}=dev
  uci set bmx6.${LOGICAL_INTERFACE}.dev=${REAL_INTERFACE}
  #uci set bmx6.${LOGICAL_INTERFACE}.globalPrefix="$( echo ${IPV6} echo | sed s/"\/.*"/"\/128"/ )"

  # To enable IPv4

  #if uci -q get bmx6.general.tun4Address > /dev/null ; then
  #  uci set bmx6.tun_${LOGICAL_INTERFACE}=tunInNet
  #  uci set bmx6.tun_${LOGICAL_INTERFACE}.tunInNet="$( echo ${IPV4} echo | sed s/"\/.*"/"\/32"/ )"
  #  uci set bmx6.tun_${LOGICAL_INTERFACE}.bandwidth="128000000000"
  #else
  #  uci set bmx6.general.tun4Address="$( echo ${IPV4} echo | sed s/"\/.*"/"\/32"/ )"
  #fi

  # Announce own cloud network

# Accept incoming tunnels

  if ! uci -q get bmx6.general.tun6Address > /dev/null ; then
    uci set bmx6.general.tun6Address=$( echo ${IPV6} | sed "s/\/.*/\/128/;s/fddf:ca\(..:[^:]\+:\)/fddf:caca:cade:/" )
    uci set bmx6.lime_own=tunInNet
    uci set bmx6.lime_own.tunInNet=$( echo ${IPV6} | sed "s/^\([^:]\+:[^:]\+:[^:]\+\):.*/\1::\/64/")
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
