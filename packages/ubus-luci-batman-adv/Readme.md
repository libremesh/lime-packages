# B.A.T.M.A.N-Adv ubus status module

|Path     |Procedure     |Signature     |Description
|---  |---  |---  |---  |---  |
|luci2.batman-adv |interfaces     |{}     | Get the list of intefaces 
|luci2.batman-adv |gateways     |{}     | Get the list of gateways
|luci2.batman-adv |originators    |{}       | Ghet the list of originators

## Examples

### ubus -v list luci2.batman-adv
```
'luci2.batman-adv' @1ae4c0f9
  "interfaces":{}
  "gateways":{}
  "originators":{}
```


### ubus call luci2.batman-adv interfaces
```json
{
  "interfaces": [
    "dummy0",
    "wlan1-adhoc_177",
    "wlan0-adhoc_177"
  ]
}
```
### ubus call luci2.batman-adv gateways
```json
{
  "gateways": [
    
  ]
}

```

### ubus call luci2.batman-adv originators
```json
{
  "originators": [
    [
      "QL-fc6565_dummy0",
      960,
      99,
      "marisa_wlan1-adhoc",
      "wlan1-adhoc_177"
    ],
        [
      "QL-fc6543_dummy0",
      410,
      93,
      "marisa_wlan1-adhoc",
      "wlan1-adhoc_177"
    ]
  ]
}

```