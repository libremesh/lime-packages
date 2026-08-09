#!/bin/sh
# shellcheck disable=SC1091

Type=
output=

if [ -n "$1" ] && [ -n "$2" ]; then
    . /usr/share/libubox/jshn.sh

    json_load "$(cat /etc/board.json)"
    json_select network
    if json_get_type Type "$1" && [ "$Type" = "object" ]; then
        json_select "$1"
        json_get_var output "$2"
    fi
fi

echo -n "${output% *}"
