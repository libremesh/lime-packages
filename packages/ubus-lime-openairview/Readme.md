# Openairview (Align / Spectrun scan) ubus status module

| Path             | Procedure          | Signature                          | Description                                                                                                                                |
| ---------------- | ------------------ | ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| lime-openairview | spectral_scan      | {device:STRING, spectrum:STRING}   | Get the fft-eval scan results. specturm can by: 2ghz, 5ghz or current. "current" means scan only the channel on which the interface is set. This will work only if fft-eval is installed |

## Examples

### ubus -v list lime-openairview

If the openairview was never established, return the openairview of the community

```
'lime-openairview' @4bd5f4f5
	"spectral_scan":{"device":"String","spectrum":"String"}
```
