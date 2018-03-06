
# Openairview (Align / Spectrun scan) ubus status module

|Path     |Procedure     |Signature     |Description
|---  |---  |---  |---
|luci2.openairview |interfaces     |{}     | Get list of adhoc interfaces
|luci2.openairview |get_stations     |{device:STRING}     | List of stations transmitting on the same frequency as the selected device/interface.

## Examples

### ubus -v list luci2.openairview
If the openairview was never established, return the openairview of the community

```
'luci2.openairview' @4bd5f4f5
  "get_interfaces":{}
  "get_stations":{"device":"String"}
  "spectral_scan":{"device":"String","spectrum":"String"}

```

### ubus call luci2.openairview get_interfaces
```json
{
  "interfaces": [
    "wlan1-adhoc",
    "wlan0-adhoc"
  ]
}

```

### ubus call luci2.openairview get_stations '{"device":"wlan1-adhoc"}'
```json
{
  "stations": [
    {
      "station_mac": "A0:F3:C1:86:31:35",
      "station_hostname": "herradura_wlan1-adhoc",
      "attributes": {
        "inactive": 16870,
        "channel": 112,
        "signal": "-82"
      },
      "link_type": "wifi"
    },
    {
      "station_mac": "A0:F3:C1:86:32:11",
      "station_hostname": "marisa_wlan1-adhoc",
      "attributes": {
        "inactive": 10,
        "channel": 112,
        "signal": "-74"
      },
      "link_type": "wifi"
    }
  ]
}
```
