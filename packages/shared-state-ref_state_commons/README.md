# Reference State

Shared-state has modules with information about the node, each
information data type like wifi_links_info may have a reference type called
wifi_links_info_ref.

Reference state is designed to contain information about the node that will
persist and that is not changed to often. This is because it is stored in the
device memory and to many consequent write operations may damage the memory. 

One thing that is important to note is that no node stores the hole status of
the network. Every node stores his own information about him and his links. 
Yo can see the information of the whole network as long as every node makes its
part. 

## Possible use cases
The reference state has many implications and possible uses :

* Troubleshooting and Diagnostics:
The reference state provides a baseline for the network's expected
behavior and performance. By comparing the current state of the network
to the reference state, you can identify and diagnose issues more
effectively.
This information can help pinpoint the source of problems, such as
connectivity issues, performance degradation, or configuration changes
that have caused the network to deviate from its expected state.
		
* Disaster Recovery:
The reference state can be used as a starting point for restoring the network in
the event of a disaster or system failure. By having reference state, you can
more quickly and accurately rebuild the network to its known, functional state.
This can help minimize downtime and ensure a faster recovery. 

* Define a list of nodes that have certain privileges: 
Setting a list of nodes as the reference state may enable bandwidth allocation
policies or enable certain type of traffic between the nodes that are in the list
of nodes from the reference state.

## Usage 
For example lets say that you have just configured your mesh network and
everything works as expected.You may want to keep all the information about
the network and define the "perfect" status, because this information may be useful
to detect deviations from the perfect status and easily identify and fix the
problem. 

You can get the information about the wifi links using this command 

```bash
shared-state-async get wifi_links_info
``` 
or using the rpcd ubus wraper 

```bash
ubus -S call shared-state-async get  '{"data_type":  "wifi_links_info" }' 

```
The output of this command obtained from a node called cheche is shown below ...
as you can see this command has information about all the nodes in the network.

```JSON
{"data":{"cheche":{"src_loc":{"long":"-64.4228178","lat":"-31.8019512"},"links":{"ae40411f73a8c64a00fc3abe":{"freq":2462,"iface":"wlan0-mesh","tx_rate":144400,"dst_mac":"c6:4a:00:fc:3a:be","channel":11,"chains":[-40,-35],"signal":-34,"rx_rate":144400,"src_mac":"ae:40:41:1f:73:a8"},"ae40411c85c3ae40411df934":{"freq":5785,"iface":"wlan2-mesh","tx_rate":300000,"dst_mac":"ae:40:41:1d:f9:34","dst_loc":{"long":"-64.42868","lat":"-31.71538"},"channel":157,"chains":[-37,-39],"signal":-35,"rx_rate":270000,"src_mac":"ae:40:41:1c:85:c3"},"ae40411c8516ae40411df935":{"freq":5240,"iface":"wlan1-mesh","tx_rate":240000,"dst_mac":"ae:40:41:1d:f9:35","dst_loc":{"long":"-64.42868","lat":"-31.71538"},"channel":48,"chains":[-65,-64],"signal":-61,"rx_rate":162000,"src_mac":"ae:40:41:1c:85:16"},"ae40411c8516c64a00fc3abf":{"freq":5240,"iface":"wlan1-mesh","tx_rate":104000,"dst_mac":"c6:4a:00:fc:3a:bf","channel":48,"chains":[-77,-82],"signal":-74,"rx_rate":60000,"src_mac":"ae:40:41:1c:85:16"}}},"graciela":{"src_loc":{"long":"-64.42868","lat":"-31.71538"},"links":{"ae40411c85c3ae40411df934":{"freq":5785,"iface":"wlan2-mesh","tx_rate":270000,"dst_mac":"ae:40:41:1c:85:c3","dst_loc":{"long":"-64.4228178","lat":"-31.8019512"},"channel":157,"chains":[-49,-32],"signal":-32,"rx_rate":300000,"src_mac":"ae:40:41:1d:f9:34"},"ae40411df935c64a00fc3abf":{"freq":5240,"iface":"wlan1-mesh","tx_rate":300000,"dst_mac":"c6:4a:00:fc:3a:bf","channel":48,"chains":[-64,-61],"signal":-59,"rx_rate":162000,"src_mac":"ae:40:41:1d:f9:35"},"ae40411c8516ae40411df935":{"freq":5240,"iface":"wlan1-mesh","tx_rate":216000,"dst_mac":"ae:40:41:1c:85:16","dst_loc":{"long":"-64.4228178","lat":"-31.8019512"},"channel":48,"chains":[-64,-59],"signal":-58,"rx_rate":243000,"src_mac":"ae:40:41:1d:f9:35"}}},"tito":{"ae40411f73a8c64a00fc3abe":{"freq":2462,"iface":"wlan0-mesh","tx_rate":144400,"dst_mac":"ae:40:41:1f:73:a8","channel":11,"chains":[-33,-34],"signal":-30,"rx_rate":144400,"src_mac":"c6:4a:00:fc:3a:be"},"ae40411c8516c64a00fc3abf":{"freq":5240,"iface":"wlan1-mesh","tx_rate":60000,"dst_mac":"ae:40:41:1c:85:16","channel":48,"chains":[-69,-64],"signal":-63,"rx_rate":104000,"src_mac":"c6:4a:00:fc:3a:bf"},"ae40411df935c64a00fc3abf":{"freq":5240,"iface":"wlan1-mesh","tx_rate":240000,"dst_mac":"ae:40:41:1d:f9:35","channel":48,"chains":[-46,-53],"signal":-45,"rx_rate":300000,"src_mac":"c6:4a:00:fc:3a:bf"}}},"error":0} 
```

If this information about cheche or part of it is relevant you may want to use
it as the reference state. This will stablish a "permanent" or "stable" 
wifi_links_info called wifi_links_info_ref


To insert a reference state just put the json part related to this node into
shared state async.

```bash
echo '{"cheche":{"src_loc":{"long":"-64.4228178","lat":"-31.8019512"},"links":{"ae40411f73a8c64a00fc3abe":{"freq":2462,"iface":"wlan0-mesh","tx_rate":144400,"dst_mac":"c6:4a:00:fc:3a:be","channel":11,"chains":[-40,-35],"signal":-34,"rx_rate":144400,"src_mac":"ae:40:41:1f:73:a8"}}}}'| shared-state-async insert wifi_links_info_ref
```
after this you can always view this node reference state in a json file located
in /etc/shared-state/ref_state/wifi_links_info_ref.json or more generically
/etc/shared-state/ref_state/<data_type>.json where datatype has to be one of the
declared shared state types. Also you can get the reference state using shared
state.  

```bash
shared-state-async get wifi_links_info_ref
``` 
or using the rpcd ubus wraper 

```bash
 ubus -S call shared-state-async get  '{"data_type":  "wifi_links_info_ref" }' 
```
```JSON
{"data":{"cheche":{"src_loc":{"long":"-64.4228178","lat":"-31.8019512"},"links":{"ae40411f73a8c64a00fc3abe":{"freq":2462,"iface":"wlan0-mesh","tx_rate":144,"dst_mac":"c6:4a:00:fc:3a:be","channel":11,"chains":[-40,-35],"signal":-34,"rx_rate":144400,"src_mac":"ae:40:41:1f:73:a8"}}},"graciela":[]},"error":0}
```
## Default initialization 
Files are in default state as an empty json object... "{}" 
Ubus call to get method will return empty array. That is a limitation of the
library. 

```bash
ubus -S call shared-state-async get  '{"data_type":  "wifi_links_info_ref" }' 
{"data":{"cheche":[],"graciela":[],"tito":[]},"error":0}
```
## Available datatypes
Data types must be declared. Available datatypes are babel_links_info_ref,
bat_links_info_ref, wifi_links_info_ref and node_info_ref
