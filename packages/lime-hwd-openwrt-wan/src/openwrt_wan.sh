#!/bin/sh

. /usr/share/libubox/jshn.sh

json_load "$(cat /etc/board.json)"

json_select network
json_select wan
json_get_var ifname ifname

echo -n "$ifname"
