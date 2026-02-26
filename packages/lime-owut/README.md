# lime-owut

A script to add LibreMesh package repositories to owut build requests (available since openwrt-24.10).

## Description
To request a firmware build, owut asks it to an asu server (online imagebuilder) [0].
This package by default instructs owut to use an asu instance [1] which allows adding feeds from libremesh.
A source code with these changes to allow libremesh repositories within asu can be found at note [2].

**owut**, OpenWrt Upgrade Tool, [3] _"is command line tool that upgrades your router's firmware. It creates custom images of OpenWrt using the sysupgrade server and installs them, retaining all of your currently installed packages and configuration."_

In LibreMesh, it can be used to update the libremesh and openwrt packages:
- while remaining with the same version of openwrt (like in the example below)
- when updating to a newer version of openwrt, whether it is a minor update (e.g., 24.10.2 -> 24.10.3) or a major update (24.10.2 -> 25.xx.xx).

**Note**: updating between major releases of OpenWrt is generally only “officially supported” between one major release and the next (i.e., 24.10.2 -> 26.xx.xx may work but is not officially supported). 

## Example output running `owut download`

```
root@LiMe-870f23:~# owut download
ASU-Server     https://sysupgrade.antennine.org
Upstream       https://downloads.openwrt.org
Target         mediatek/filogic
Profile        cudy_wr3000s-v1
Package-arch   aarch64_cortex-a53
Version-from   24.10.2 r28739-d9340319c6 (kernel 6.6.93)
Version-to     24.10.2 r28739-d9340319c6 (kernel 6.6.93)
55 packages are out-of-date
WARNING: There are 3 missing default packages, confirm this is expected before proceeding
Request hash:
  37c114d672897c322b6ef12ef6f91e809052a032272544e711c891045037c270
--
Status:   queued - 0 ahead of you
Progress:   0s total =   0s in queue +   0s in build
--
Status:   init
Progress:   1s total =   0s in queue +   1s in build
--
Status:   validate_manifest
Progress:  49s total =   0s in queue +  49s in build
--
Status:   building_image
Progress:  86s total =   0s in queue +  86s in build
--
Status:   done
Progress:  89s total =   0s in queue +  89s in build

Build succeeded in  89s total =   0s in queue +  89s to build:
Image saved : /tmp/firmware.bin
```

## Notes
This package may be deprecated in the future, since it adds repo_feeds and repo_keys from libremesh
And the ability to use additional feeds, within /etc/(opkg|apk), could perhaps be added to the core of owut itself.

[0] https://github.com/openwrt/asu    
[1] https://sysupgrade.antennine.org    
[2] https://github.com/a-gave/asu-libremesh    
[3] https://github.com/efahl/owut    
