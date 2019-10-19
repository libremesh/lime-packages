# Utils Libremesh ubus status module

Procedure | Signature | Description |
 --------------- | ----------------|------------------ |
| get_cloud_nodes | {} | Get cloud nodes |
| safe_reboot     | { "action": "status" } | Get safe-reboot status|
| safe_reboot     | { "action": "start", "value": {"wait": TIME, "fallback": TIME } } | After backing up /overlay/upper/etc, wait for TIME (value.wait) before reboot (Default: 5min). After boot, wait for TIME (value.fallback) before reverting /overlay/upper/etc from backup found in /overlay/upper/.etc.last-good.tgz (Default: 10min).<br> _TIME examples: 1hour 60min 60m 3600sec 3600 (all of them are equivalent)_ |
| safe_reboot     | { "action": "now" }                                               | Do not make /overlay/upper/etc backup; instead check that there's one already in place (/overlay/upper/.etc.last-good.tgz,then reboot and wait for fallback timeout.                                                                                                                                                                  |
| safe_reboot     | { "action": "cancel" }| Remove /overlay/upper/.etc.last-good.tgz (useful after a successful reboot)|
| safe_reboot     | { "action": "discard" } | Restores /overlay/upper/etc from /overlay/upper/.etc.last-good.tgz (useful to discard changes)|
| get_community_settings     | {} | Returns custom values for the community, this is useful for limeApp|
| get_config     | {} | Returns wifi and netwrok configuration from /etc/config/lime |
| set_notes     | {"text":"String"} | Write notes to /etc/banner |
| get_notes     | {} | Get notes fom /etc/banner |
| change_config     | {"name":"String","ip":"String"} | Change the name of the router and the ipv4 |
| get_node_status | {} | Returns the state of the node (uptime, ipv4 and ipv6 addresses, most active link, etc) |

## Examples

### ubus -v list lime-utils

```
'lime-utils' @fb3a2ef0
	"get_cloud_nodes":{"no_params":"Integer"}
	"get_community_settings":{"no_params":"Integer"}
	"get_config":{"no_params":"Integer"}
	"set_notes":{"text":"String"}
	"change_config":{"name":"String","ip":"String"}
	"safe_reboot":{"action":"String","value":"String"}
	"get_notes":{"no_params":"Integer"}
	"get_node_status":{"no_params":"Integer"}
```
