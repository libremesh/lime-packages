#!/bin/sh
[ "x$ACTION" == "xifup" ] && ((sleep 30; shared-state-publish_bat_hosts; shared-state sync bat-hosts)&)
