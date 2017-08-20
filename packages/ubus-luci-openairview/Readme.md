
# Openairview (Align / Spectrun scan) ubus status module

|Path     |Procedure     |Signature     |Description
|---  |---  |---  |---  |---  |
|luci2.openairview |interfaces     |{}     | Get list of interfaces
|luci2.openairview |get_stations     |{device:STRING}     | List of stations transmitting on the same frequency as the selected device/interface.
|luci2.openairview |spectral_scan     |{device:STRING, spectrum:STRING}     |Scan the spectrum ("5ghz","2ghz" or "current") of the device whit fft_eval.
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
    "wlan1-ap",
    "wlan0-adhoc_13",
    "wlan1-adhoc_177",
    "wlan1-adhoc_13",
    "wlan0-adhoc_177",
    "wlan1-adhoc",
    "wlan0-ap",
    "wlan0-adhoc"
  ]
}

```

### ubus call luci2.openairview get_stations '{"device":"wlan1-adhoc"}'
```json
{
  "stations": [
    {
      "type": "wifi",
      "station_hostname": "lm123_wlan1-adhoc",
      "station": "A0:F3:C1:86:32:11",
      "attributes": {
        "inactive": 0,
        "channel": 112,
        "signal": -72
      }
    }
  ]
}
```

### ubus call luci2.openairview spectral_scan '{"device":"wlan1-adhoc","spectrum":"5ghz"}'
```json
{
  "spectrum": {
    "epoch": 1503185784,
    "samples": [
      {
        "noise": -91,
        "central_freq": 5240,
        "rssi": 14,
        "data": [
          [
            "5230",
            "-105.75531"
          ],
          [
            "5230.356934",
            "-102.23349"
          ],
          [
            "5230.714355",
            "-97.796516"
          ],
          [
            "5231.071289",
            "-96.212891"
          ],
          [
            "5231.428711",
            "-111.775917"
          ],
          [
            "5231.785645",
            "-94.873955"
          ],
          [
            "5232.143066",
            "-97.796516"
          ],
          [
            "5232.5",
            "-92.691071"
          ],
          [
            "5232.856934",
            "-86.670471"
          ],
          [
            "5233.214355",
            "-92.691071"
          ],
          [
            "5233.571289",
            "-111.775917"
          ],
          [
            "5233.928711",
            "-94.873955"
          ],
          [
            "5234.285645",
            "-96.212891"
          ],
          [
            "5234.643066",
            "-94.873955"
          ],
          [
            "5235",
            "-92.691071"
          ],
          [
            "5235.356934",
            "-96.212891"
          ],
          [
            "5235.714355",
            "-97.796516"
          ],
          [
            "5236.071289",
            "-94.873955"
          ],
          [
            "5236.428711",
            "-96.212891"
          ],
          [
            "5236.785645",
            "-111.775917"
          ],
          [
            "5237.143066",
            "-91.775917"
          ],
          [
            "5237.5",
            "-111.775917"
          ],
          [
            "5237.856934",
            "-90.192291"
          ],
          [
            "5238.214355",
            "-96.212891"
          ],
          [
            "5238.571289",
            "-99.734718"
          ],
          [
            "5238.928711",
            "-102.23349"
          ],
          [
            "5239.285645",
            "-102.23349"
          ],
          [
            "5239.643066",
            "-93.714111"
          ],
          [
            "5240",
            "-94.274689"
          ],
          [
            "5240.356934",
            "-94.873955"
          ],
          [
            "5240.714355",
            "-102.23349"
          ],
          [
            "5241.071289",
            "-91.775917"
          ],
          [
            "5241.428711",
            "-91.775917"
          ],
          [
            "5241.785645",
            "-97.796516"
          ],
          [
            "5242.143066",
            "-102.23349"
          ],
          [
            "5242.5",
            "-96.212891"
          ],
          [
            "5242.856934",
            "-92.691071"
          ],
          [
            "5243.214355",
            "-97.796516"
          ],
          [
            "5243.571289",
            "-91.775917"
          ],
          [
            "5243.928711",
            "-97.796516"
          ],
          [
            "5244.285645",
            "-97.796516"
          ],
          [
            "5244.643066",
            "-102.23349"
          ],
          [
            "5245",
            "-91.775917"
          ],
          [
            "5245.356934",
            "-96.212891"
          ],
          [
            "5245.714355",
            "-94.873955"
          ],
          [
            "5246.071289",
            "-96.212891"
          ],
          [
            "5246.428711",
            "-92.691071"
          ],
          [
            "5246.785645",
            "-89.497047"
          ],
          [
            "5247.143066",
            "-111.775917"
          ],
          [
            "5247.5",
            "-97.796516"
          ],
          [
            "5247.856934",
            "-87.166931"
          ],
          [
            "5248.214355",
            "-111.775917"
          ],
          [
            "5248.571289",
            "-90.948059"
          ],
          [
            "5248.928711",
            "-105.75531"
          ],
          [
            "5249.285645",
            "-111.775917"
          ],
          [
            "5249.643066",
            "-93.714111"
          ]
        ],
        "tsf": 0
      }
    ]
  }
}
```