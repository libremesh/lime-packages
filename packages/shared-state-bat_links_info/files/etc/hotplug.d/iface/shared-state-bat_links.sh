#!/bin/sh
[ "x$ACTION" == "xifup" ] && ((sleep 30; /usr/share/shared-state/publishers/shared-state-publish_bat_links)&)
