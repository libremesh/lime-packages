# BMX6 ubus status module

|Path     |Procedure     |Signature     |Description
|---     |---  |---  |---  |---  |
|luci2.bmx6 |links     |{"host": STRING }     | Get the list of bmx6 links by interface. "host" can be an IPv4, IPV6, or device name. If "host" is not defined the query is local.
|luci2.bmx6 |status     |{}     | Get the current status of bmx6 and the list of interfaces
|luci2.bmx6 |tunnels    |{}       | Get the list Of bmx6 tunnes
|luci2.bmx6 |originators|{}       | Get the list of bmx6 originators
|luci2.bmx6 |topology   |{}       | It performs a topological exploration between the nodes and returns the links status. Generate a cache in / tmp and the result can be different for each call (depends on the size of the network) 

## Examples

### ubus -v list luci2.bmx6
```
'luci2.bmx6' @91edd5ea
  "links":{"host":"String"}
  "status":{}
  "topology":{}
  "tunnels":{}
  "originators":{}

```

### ubus call luci2.bmx6 links
Local bmx links query
```json
{
  "links": {
	"wlan1-adhoc_13": [
	  {
		"routes": 67,
		"viaDev": "wlan1-adhoc_13",
		"name": "Flmb-222",
		"bestTxLink": 1,
		"txRate": 95,
		"wantsOgms": 1,
		"rxRate": 100,
		"llocalIp": "fe80::a2f3:c1ff:fe86:3211"
	  }
	]
  }
}

```

### ubus call luci2.bmx6 links '{"host":"Flmb-222"}'
Remote bmx links query
```json
{
  "links": {
	"wlan0-adhoc_13": [
	  {
		"routes": 6,
		"viaDev": "wlan0-adhoc_13",
		"name": "Flmb-1123",
		"bestTxLink": 1,
		"txRate": 100,
		"wantsOgms": 1,
		"rxRate": 75,
		"llocalIp": "fe80::16cc:20ff:fe75:b527"
	  }
	],
	"wlan1-adhoc_13": [
	  {
		"routes": 1,
		"viaDev": "wlan1-adhoc_13",
		"name": "Flmb-nys",
		"bestTxLink": 1,
		"txRate": 100,
		"wantsOgms": 1,
		"rxRate": 87,
		"llocalIp": "fe80::4321:b3ff:fe87:2fbd"
	  },
	  {
		"routes": 1,
		"viaDev": "wlan1-adhoc_13",
		"name": "Flmb-rr",
		"bestTxLink": 1,
		"txRate": 97,
		"wantsOgms": 1,
		"rxRate": 100,
		"llocalIp": "fe80::a2f3:c1ff:fe46:2837"
	  }
	]
  }
}
```

### ubus call luci2.bmx6 status
```json
{
  "status": {
	"compat": 16,
	"primaryIp": "fd66:66:66:8:4321:b3ff:fe87:2fbb",
	"tun6Address": "2801:1e8:2::bb2f:8700\/64",
	"name": "natisofi",
	"nodes": 68,
	"cpu": "1.8",
	"version": "BMX6-0.1-alpha",
	"uptime": "0:01:10:20",
	"tun4Address": "10.5.0.85\/21"
  },
  "interfaces": [
	{
	  "state": "UP",
	  "type": "ethernet",
	  "primary": 1,
	  "globalIp": "fd66:66:66:8:4321:b3ff:fe87:2fbb\/64",
	  "devName": "br-lan",
	  "rateMin": "1000M",
	  "rateMax": "1000M",
	  "llocalIp": "fe80::4321:b3ff:fe87:2fbb\/64"
	},
	{
	  "state": "UP",
	  "type": "ethernet",
	  "primary": 0,
	  "globalIp": "fd66:66:66:12:4321:b3ff:fe87:2fbc\/64",
	  "devName": "wlan0-adhoc_13",
	  "rateMin": "54000",
	  "rateMax": "54000",
	  "llocalIp": "fe80::4321:b3ff:fe87:2fbc\/64"
	},
	{
	  "state": "UP",
	  "type": "ethernet",
	  "primary": 0,
	  "globalIp": "fd66:66:66:10:4321:b3ff:fe87:2fbd\/64",
	  "devName": "wlan1-adhoc_13",
	  "rateMin": "54000",
	  "rateMax": "54000",
	  "llocalIp": "fe80::4321:b3ff:fe87:2fbd\/64"
	}
  ]
}


```

### ubus call luci2.bmx6 tunnels
```json
{
  "tunnels": [
	{
	  "advBw": "128G",
	  "tunName": "---",
	  "remoteTunIp": "fd66:66:66:11:16cc:20ff:fead:b0e5",
	  "advBwVal": "128G",
	  "localTunIp": "fd66:66:66:ff00:16cc:20ff:fead:b0e5",
	  "tunMtc": "19968",
	  "tunMtcVal": "19968",
	  "remoteName": "si-34432",
	  "src": "---",
	  "srcIngress": "0.0.0.0\/0",
	  "table": 254,
	  "tunId": 0,
	  "rating": 100,
	  "minBw": "960",
	  "advNet": "10.5.0.0\/21",
	  "pathMtc": "20187",
	  "ipMtc": 1024,
	  "id": ".",
	  "hyst": 20,
	  "max": 128,
	  "bOSP": 1,
	  "advType": "unspecified",
	  "aOLP": 1,
	  "min": 8,
	  "tunRoute": "10.5.0.0\/21",
	  "name": "clouds",
	  "net": "10.0.0.0\/8",
	  "type": "---",
	  "tunIn": "---",
	  "pref": 32766,
	  "remoteId": "si-fliasosa.3CB2499257998B07FD0A"

	},....

  ]
}

```


### ubus call luci2.bmx6 topology
```json
{
  "topology": [
	{
	  "name": "QL-02",
	  "links": [
		{
		  "txRate": 81,
		  "rxRate": 100,
		  "name": "QL-01"
		},
		{
		  "txRate": 34,
		  "rxRate": 58,
		  "name": "QL-03"
		}
	  ]
	},
	{
	  "name": "QL-01",
	  "links": [
		{
		  "txRate": 100,
		  "rxRate": 81,
		  "name": "QL-02"
		}
	  ]
	},
	{
	  "name": "QL-03",
	  "links": [
		{
		  "txRate": 42,
		  "rxRate": 38,
		  "name": "QL-02"
		}
	  ]
	}
  ]
}

```


## ubus call luci2.bmx6 originators
```json
{
  "originators": [
	{
	  "orig": {
		"primaryIp": "fd66:66:66:8:c24a:ff:fefc:6565",
		"viaDev": "wlan1-adhoc_13",
		"routes": 1,
		"viaIp": "fe80::a2f3:c1ff:fe86:3211",
		"blocked": 0,
		"metric": "20496",
		"lastDesc": 1482,
		"lastRef": 2,
		"name": "QL-fc6565"
	  },
	  "name": "QL-fc6565",
	  "desc": {
		"descSha": "D21D09A516F1BC612D772624A1BAC5DB4719A5C0",
		"DESC_ADV": {
		  "capabilities": "0",
		  "ogmSqnMin": 49678,
		  "extensions": [
			{
			  "METRIC_EXTENSION": [
				{
				  "pathRegression": 1,
				  "rxExpNumerator": 64,
				  "metricAlgo": 16,
				  "txExpNumerator": 128,
				  "flags": "0",
				  "pathLounge": 1,
				  "rxExpDivisor": 64,
				  "fmetric_u16_min": "1",
				  "txExpDivisor": 64,
				  "hopPenalty": 0,
				  "pathWindow": 5
				}
			  ]
			},
			{
			  "HNA6_EXTENSION": [
				{
				  "address": "fd66:66:66:8:c24a:ff:fefc:6565",
				  "prefixlen": 128
				},
				{
				  "address": "fd66:66:66:12:c24a:ff:fefc:6566",
				  "prefixlen": 128
				},
				{
				  "address": "fd66:66:66:10:c24a:ff:fefc:6567",
				  "prefixlen": 128
				},
				{
				  "address": "fd66:66:66:ff00:c24a:ff:fefc:6565",
				  "prefixlen": 128
				}
			  ]
			},
			{
			  "TUN6_EXTENSION": [
				{
				  "localIp": "fd66:66:66:ff00:c24a:ff:fefc:6565"
				}
			  ]
			},
			{
			  "TUN4IN6_NET_EXTENSION": [
				{
				  "bandwidth": "128G",
				  "network": "10.5.0.0",
				  "rtype": 0,
				  "tun6Id": 0,
				  "networklen": 21
				}
			  ]
			},
			{
			  "TUN6IN6_NET_EXTENSION": [
				{
				  "bandwidth": "128G",
				  "network": "2801:1e8:2::",
				  "rtype":
				   0,
				  "tun6Id": 0,
				  "networklen": 64
				}
			  ]
			}
		  ],
		  "descSqn": 53926,
		  "globalId": "QL-fc6565.85AD82FB2B5E1CE2460D",
		  "txInterval": 500,
		  "revision": "4016",
		  "transmitterIid4x": 5,
		  "ogmSqnRange": 7345
		},
		"blocked": 0
	  }
	},
	{
	  ....
	}
  ]
}

```