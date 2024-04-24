#!/bin/sh
[ "x$ACTION" == "xifup" ] && ((sleep 30; /usr/share/shared-state/publishers/shared-state-publish_bat_hosts; shared-state-async sync bat-hosts)&)
