#!/bin/sh

. /usr/share/libubox/jshn.sh

json_load "$(cat /etc/board.json)"

json_select network
if json_get_type Type wan && [ "$Type" == object ]; then
    json_select wan
    json_get_var ifname ifname
else
    ifname=""
fi

echo -n "$ifname"
