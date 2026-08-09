#!/bin/sh
[ "$ACTION" = "ifup" ] && ( sleep 30; /usr/share/shared-state/publishers/shared-state-publish_bat_hosts ) &
