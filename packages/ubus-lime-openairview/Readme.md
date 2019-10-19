# Openairview (Align / Spectrun scan) ubus status module

| Path             | Procedure          | Signature                          | Description                                                                                                                                |
| ---------------- | ------------------ | ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| lime-openairview | get_interfaces     | {}                                 | Get list of adhoc interfaces                                                                                                               |
| lime-openairview | get_stations       | {device:STRING}                    | List of stations transmitting on the same frequency as the selected device/interface.                                                      |
| lime-openairview | get_iface_stations | {iface:STRING}                     | List of stations attached to the interface.                                                                                                |
| lime-openairview | get_station_signal | {station_mac:STRING, iface:STRING} | Get the signal level with which an interface sees a particular device                                                                      |
| lime-openairview | spectral_scan      | {device:STRING, spectrum:STRING}   | Get the fft-eval scan results. specturm can by: 2ghz, 5ghz or current. "current" means scan only the channel on which the interface is set. This will work only if fft-eval is installed |

## Examples

### ubus -v list lime-openairview

If the openairview was never established, return the openairview of the community

```
'lime-openairview' @4bd5f4f5
	"get_interfaces":{"no_params":"Integer"}
 "get_stations":{"device":"String"}
	"get_iface_stations":{"iface":"String"}
	"get_station_signal":{"station_mac":"String","iface":"String"}
	"spectral_scan":{"device":"String","spectrum":"String"}
```

### ubus call lime-openairview get_interfaces

```json
{
  "interfaces": ["wlan1-adhoc", "wlan0-adhoc"]
}
```

### ubus call lime-openairview get_stations '{"device":"wlan1-adhoc"}'

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
