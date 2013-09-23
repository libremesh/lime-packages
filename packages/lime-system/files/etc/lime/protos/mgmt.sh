#!/bin/sh

ACTION=$1
LOGICAL_INTERFACE=$2
REAL_INTERFACE=$3
IPV4=$4
IPV6=$5
R1=$6
R2=$7

clean () {
  true  
}

prepare () {
  uci set batman-adv.bat1=mesh
  uci set batman-adv.bat1.orig_interval=600
  uci set batman-adv.bat1.bridge_loop_avoidance=1
  uci commit batman-adv

  uci set dhcp.@dnsmasq[0].domainneeded=0
  uci set dhcp.@dnsmasq[0].boguspriv=0
  uci set dhcp.@dnsmasq[0].rebind_protection=0
  uci set dhcp.mgmt=dhcp
  uci set dhcp.mgmt.interface=mgmt
  uci set dhcp.mgmt.ignore=1
  uci commit dhcp

  uci set network.mgmt=interface
  uci set network.mgmt.ifname=bat1
  uci set network.mgmt.proto=dhcp

  uci set network.mgmt_v6=interface
  uci set network.mgmt_v6.ifname="@mgmt"
  uci set network.mgmt_v6.proto=dhcpv6
  uci set network.mgmt_v6.reqprefix=no
  uci commit network

  uci add firewall zone
  uci set firewall.@zone[-1].name=mgmt
  uci set firewall.@zone[-1].network=mgmt
  uci set firewall.@zone[-1].input=ACCEPT
  uci set firewall.@zone[-1].output=ACCEPT
  uci set firewall.@zone[-1].forward=ACCEPT
  uci set firewall.@zone[-1].masq=1
  uci set firewall.@zone[-1].mtu_fix=1

  uci add firewall forwarding
  uci set firewall.@forwarding[-1].src=lan
  uci set firewall.@forwarding[-1].dest=mgmt
  uci commit firewall
}

add () {
  if [ "$(uci -q get network.mgmt.macaddr)" == "" ]; then
    uci set network.mgmt.macaddr="$(printf '02:ba:fe:%02x:%02x:01' $R1 $R2)"
  fi

  uci set network.${LOGICAL_INTERFACE}=interface
  uci set network.${LOGICAL_INTERFACE}.proto=batadv
  uci set network.${LOGICAL_INTERFACE}.mesh=bat1
  uci set network.${LOGICAL_INTERFACE}.mtu=1528
  uci commit network
}

$ACTION
