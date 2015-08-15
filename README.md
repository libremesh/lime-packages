[![tip for next commit](http://tip4commit.com/projects/804.svg)](http://tip4commit.com/projects/804)

# Libre-Mesh packages "Big Bang" release (14.07)

[Libre-Mesh project][5] includes the development of several tools used for deploying libre/free mesh networks, check the [objectives and agreements][3].

The firmware (the main piece) will allow simple deployment of auto-configurable, yet versatile, multi-radio mesh networks. Check the [Network Architecture][4] to see the basic ideas.

## Building a firmware image

This packages feed is meant to be used with an [OpenWrt buildroot][1], simply including a line like this in `feeds.conf`

```
src-git lime_packages git://github.com/libre-mesh/lime-packages.git
```

The easiest way to get a development/build environment set up properly, is by using our tool [lime-build][2],
specially if you don't have an openwrt buildroot already.

[1]: http://wiki.openwrt.org/doc/start#building_openwrt
[2]: https://github.com/libre-mesh/lime-build
[3]: http://libre-mesh.org/projects/libre-mesh/wiki/Objectives
[4]: http://libre-mesh.org/projects/libre-mesh/wiki/Network_Architecture
[5]: http://libre-mesh.org/
