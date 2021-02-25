# babeld-auto-gw-mode

By default babeld will redistribute all the routes installed even if they "don't work". For example
when the internet provider use DHCP and the service is not working but interface is up, the route is
installed but not working and babeld will anounce the non working route to the network and also
this route will be used by this node to route the packets so also all its clients won't have internet.

This package provides a solution using watchping hooks that:
* on wan OK
  - adds a route with a special protocol number (7)
* on wan FAIL
  - removes the default route with proto 7
  - changes the metric of the default route to 84831. If other nodes are also gateways their babel
  redistributable routes will have priority over this route at this node and for that reason the
  default gateway won't be the local non working connection.

