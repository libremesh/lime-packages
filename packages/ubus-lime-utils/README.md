# Utils Libremesh ubus status module

| Path       | Procedure       | Signature                                                         | Description                                                                                                                                                                                                                                                                                                                           |
| ---------- | --------------- | ----------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| lime-utils | get_cloud_nodes | {}                                                                | Get cloud nodes                                                                                                                                                                                                                                                                                                                       |
| lime-utils | safe_reboot     | { "action": "status" }                                            | Get safe-reboot status                                                                                                                                                                                                                                                                                                                |
| lime-utils | safe_reboot     | { "action": "start", "value": {"wait": TIME, "fallback": TIME } } | After backing up /overlay/upper/etc, wait for TIME (value.wait) before reboot (Default: 5min). After boot, wait for TIME (value.fallback) before reverting /overlay/upper/etc from backup found in /overlay/upper/.etc.last-good.tgz (Default: 10min).<br> _TIME examples: 1hour 60min 60m 3600sec 3600 (all of them are equivalent)_ |
| lime-utils | safe_reboot     | { "action": "now" }                                               | Do not make /overlay/upper/etc backup; instead check that there's one already in place (/overlay/upper/.etc.last-good.tgz,then reboot and wait for fallback timeout.                                                                                                                                                                  |
| lime-utils | safe_reboot     | { "action": "cancel" }                                            | Remove /overlay/upper/.etc.last-good.tgz (useful after a successful reboot)                                                                                                                                                                                                                                                           |
| lime-utils | safe_reboot     | { "action": "discard" }                                           | Restores /overlay/upper/etc from /overlay/upper/.etc.last-good.tgz (useful to discard changes)                                                                                                                                                                                                                                        |

## Examples

### ubus -v list lime-utils

```
'lime-utils' @3c52d0ab
	"get_cloud_nodes":{"no_params":"Integer"}
	"get_community_settings":{"no_params":"Integer"}
	"set_notes":{"text":"String"}
	"change_config":{"name":"String","ip":"String"}
	"get_notes":{"no_params":"Integer"}
	"get_node_status":{"no_params":"Integer"}
	"safe_reboot":{"action":"String","value":"Table"}
```
