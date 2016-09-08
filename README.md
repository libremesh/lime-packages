[![tip for next commit](http://tip4commit.com/projects/804.svg)](http://tip4commit.com/projects/804)

# [LibreMesh][5] packages "Community Chaos" release (16.07)

[LibreMesh project][5] includes the development of several tools used for deploying libre/free mesh networks, check the [objectives and agreements][3].

The firmware (the main piece) will allow simple deployment of auto-configurable, yet versatile, multi-radio mesh networks. Check the [Network Architecture][4] to see the basic ideas.

## Building a firmware image

The LibreMesh firmware can be compiled either manually adding the feed to a [OpenWrt buildroot][1] environment or using the easy to use [lime-build][2] tool.

### Using OpenWrt buildroot

For a more detailed compilation guide refer to [our wiki][6].

Clone OpenWRT stable repository, nowadays is version 15.05 (Chaos Calmer).

    git clone git://git.openwrt.org/15.05/openwrt.git

Add lime-packages feed to the default ones.

    cd openwrt
    cp feeds.conf.default feeds.conf
    echo "src-git lime https://github.com/libremesh/lime-packages.git" >> feeds.conf

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

## Get in Touch with LibreMesh Community

### Mailing Lists

The project offers the following mailing lists

* [dev@lists.libre-mesh.org][7] - This list is used for general development related work.
* [users@lists.libre-mesh.org][8] - This list is used for project organisational purposes. And for user specific questions.

### IRC Channel

The project uses an IRC channel on freenode

* #libremesh - a public channel for everyone to join and participate

[1]: http://wiki.openwrt.org/doc/start#building_openwrt
[2]: https://github.com/libremesh/lime-build
[3]: http://libremesh.org/projects/libremesh/wiki/Objectives
[4]: http://libremesh.org/projects/libremesh/wiki/Network_Architecture
[5]: http://libremesh.org/
[6]: http://libremesh.org/projects/libremesh/wiki/Compile_Manually
[7]: https://lists.libre-mesh.org/mailman/listinfo/dev
[8]: https://lists.libre-mesh.org/mailman/listinfo/users
