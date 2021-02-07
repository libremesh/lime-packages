# babeld-auto-gw-mode

By default babeld will redistribute all the routes installed even if they "don't work". For example
when the internet provider use DHCP and the service is not working but interface is up, the route is
installed but not working and babeld will anounce the non working route to the network.

This package provides a solucion using watchping hooks that adds routes with a special protocol number
(7) when the WAN port has a working internet access and removes this route when the internet connection
is not working as detected by watchping.
