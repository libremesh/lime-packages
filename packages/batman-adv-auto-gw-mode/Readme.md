## batman-adv-auto-gw-mode

This package adds watchping hooks that set **gw_mode=server** when WAN port gets internet access and **gw_mode=client** when connection is severed.

Also adds a hotplug.d hook that sends a DHCP request when another batman-adv router announces itself as a **gw_mode=server**.

So if you install this package on every node of a batman-adv mesh network, you can connect internet access to the WAN port of any (one or more) nodes, it will be autodetected and the rest of the nodes will route through it (or them).