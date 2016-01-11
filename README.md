[![tip for next commit](http://tip4commit.com/projects/804.svg)](http://tip4commit.com/projects/804)

# Libre-Mesh packages "Big Bang" release (14.07)

[Libre-Mesh project][5] includes the development of several tools used for deploying libre/free mesh networks, check the [objectives and agreements][3].

The firmware (the main piece) will allow simple deployment of auto-configurable, yet versatile, multi-radio mesh networks. Check the [Network Architecture][4] to see the basic ideas.

## Building a firmware image

The Libre-Mesh firmware can be compiled either manually; adding the feed to a [OpenWrt buildroot][1] environment or by using the easy to use [lime-build][2] tool.

### Using OpenWrt buildroot

For full and detailed compilation guide refer to [our wiki][6].

Clone OpenWRT stable repository, nowadays is version 14.07 (Barrier Breaker).

    git clone git://git.openwrt.org/14.07/openwrt.git

Add lime-packages feed to the default ones.

    cd openwrt
    cp feeds.conf.default feeds.conf
    echo "src-git lime https://github.com/libre-mesh/lime-packages.git" >> feeds.conf

Download the new packages.

    scripts/feeds update -a
    scripts/feeds install -a

Select needed packages from LiMe menu in menuconfig.

    make menuconfig

Compile the firmware images.

    make

The resulting files will be present in bin/ directory.

### Using lime-build

Refer to [lime-build][2] documentation.

[1]: http://wiki.openwrt.org/doc/start#building_openwrt
[2]: https://github.com/libre-mesh/lime-build
[3]: http://libre-mesh.org/projects/libre-mesh/wiki/Objectives
[4]: http://libre-mesh.org/projects/libre-mesh/wiki/Network_Architecture
[5]: http://libre-mesh.org/
[6]: http://libre-mesh.org/projects/libre-mesh/wiki/Compile_Manually
