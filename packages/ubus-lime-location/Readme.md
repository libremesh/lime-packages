# Location (Libremap) ubus status module

| Path           | Procedure | Signature                | Description          |
| -------------- | --------- | ------------------------ | -------------------- |
| luci2.location | get       | {}                       | Get current location |
| luci2.location | set       | {lon:STRING, lat:STRING} | Set new location     |

## Examples

### ubus -v list luci2.location

If the location was never established, return the location of the community

```
'luci2.location' @8a28f605
	"set":{"lon":"String","lat":"String"}
	"get":{}
```

### ubus call luci2.location get

```json
{
  "location": {
    "lon": "-64.43289933588837",
    "lat": "-31.800211834083036"
  },
  "default": true // (is community location or custom location)
}
```

### ubus call luci2.location set '{"lon":"-64.13289933588837","lat":"-31.000211834083036"}'

```json
{
  "lon": "-64.13289933588837",
  "lat": "-31.000211834083036"
}
```
