# FirstBootWizard Libremesh ubus module

| Path     | Procedure       |  Description                              |
| -------- | --------------- | ----------------------------------------- |
| lime-fbw | status          | Get FBW status (scanning, lock, disabled) |
| lime-fbw | create_network  | Create a new network                      |
| lime-fbw | search_networks | Get all networks (true force rescan)      |
| lime-fbw | set_network     | Use one of the results                    |

### ubus -v list lime-fbw

```
''lime-fbw' @4c5b89e0
	"status":{}
	"create_network":{"network":"String","hostname":"String", "password": "String"}
	"search_networks":{"scan":"Boolean"}
	"set_network":{"hostname":"String","file":"String"}
```
