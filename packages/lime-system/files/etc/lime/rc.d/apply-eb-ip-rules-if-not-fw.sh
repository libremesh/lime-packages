#!/bin/sh
[ ! -e /etc/rc.d/S??firewall ] && {
  echo "$0: Firewall is not enabled. Executing firewall.user scripts."
  sh /etc/firewall.user.d/*
}
