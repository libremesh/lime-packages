#!/bin/sh
echo "Configuring LiMe testbed for first boot..."
uci add_list uhttpd.main.listen_https="[::]:443"
uci add_list uhttpd.main.listen_http="[::]:80"
uci commit uhttpd
lua /usr/bin/lime-config
