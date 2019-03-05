# FirstBootWizard Libremesh ubus module

| Path     | Procedure       | Signature          | Description                               |
| -------- | --------------- | ------------------ | ----------------------------------------- |
| lime-fbw | status          | {}                 | Get FBW status (scanning, lock, disabled) |
| lime-fbw | create_network  | {"name": "string"} | Create network                            |
| lime-fbw | search_networks | {"scan": true      | false}                                    | Get all networks (true force rescan) |
| lime-fbw | set_network     | {"file": "string"} | Use one of the results                    |

## Examples

### ubus -v list lime-fbw

```
''lime-fbw' @4c5b89e0
	"status":{}
	"create_network":{"name":"String"}
	"search_networks":{"scan":"Boolean"}
	"set_network":{"file":"String"}
```
