#!/bin/sh

#set -x

#ACTIONS are: add prepare clean?
# example: $0 <action> <virtual_if> <actual_if> <IPv4/16> <IPv6/64>


ACTION=$1
LOGICAL_INTERFACE=$2
REAL_INTERFACE=$3
IPV4=$4
IPV6=$5

clean () {
  uci revert babeld
  rm /etc/config/babeld
  touch /etc/config/babeld
}

prepare () {
  clean

  touch /etc/config/babeld

  uci add babeld filter
  uci set babeld.@filter[-1].ignore=false
  uci set babeld.@filter[-1].type=redistribute
  uci set babeld.@filter[-1].local=1
  uci set babeld.@filter[-1].action=deny

  uci commit babeld
}

add () {
  uci set babeld.${LOGICAL_INTERFACE}=interface
  uci set babeld.${LOGICAL_INTERFACE}.ignore=false

  uci add babeld filter
  uci set babeld.@filter[-1].ignore=false
  uci set babeld.@filter[-1].type=redistribute
  uci set babeld.@filter[-1].ip="${IPV6}"

  uci commit babeld
}

$ACTION
