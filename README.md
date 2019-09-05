[![travis](https://api.travis-ci.org/libremesh/lime-packages.svg?branch=develop)](https://travis-ci.org/libremesh/lime-packages)
[![Backers on Open Collective](https://opencollective.com/libremesh/backers/badge.svg)](#backers) 
[![Sponsors on Open Collective](https://opencollective.com/libremesh/sponsors/badge.svg)](#sponsors) 

# [LibreMesh][5] packages

[![LibreMesh logo](https://raw.githubusercontent.com/libremesh/lime-web/master/logo/logo.png)](http://libremesh.org)

[LibreMesh project][5] includes the development of several tools used for deploying libre/free mesh networks.

The firmware (the main piece) will allow simple deployment of auto-configurable,
yet versatile, multi-radio mesh networks. Check the [Network Architecture][4] to
see the basic ideas.

## Download Precompiled Binaries

This is the easiest way to first test and install LibreMesh in your router.

You can download a firmware image with **generic configuration** of the last
**release** at [downloads][9] subdomain.

## Customize and Download a Firmware Image Using online Chef (ImageBuilder)

We encourage each network community to create its firmware profile on
[network-profiles][10] repository and build the images with the [online
Chef][11].

## Building a Firmware Image on Your PC

The LibreMesh firmware can be compiled either using the easy to use
[lime-sdk][2] tool (recommended) or manually adding the feed to a [OpenWrt
buildroot][1] environment.

### Using lime-sdk

Refer to [lime-sdk][2] README.

### Using OpenWrt buildroot

Clone OpenWrt stable repository, nowadays is version 18.06.1.

    git clone https://www.github.com/openwrt/openwrt -b openwrt-18.06
    cd openwrt

Add lime-packages, libremap and lime-ui-ng feeds to the default ones.

    cp feeds.conf.default feeds.conf
    echo "src-git libremesh https://github.com/libremesh/lime-packages.git" >> feeds.conf
    echo "src-git libremap https://github.com/libremap/libremap-agent-openwrt.git" >> feeds.conf
    echo "src-git limeui https://github.com/libremesh/lime-ui-ng.git" >> feeds.conf

If you want to use a specific branch of lime-packages specify it adding
;nameofthebranch at the end of the relative line. For example:

    src-git lime https://github.com/libremesh/lime-packages.git;17.06

Download the new packages.

    scripts/feeds update -a
    scripts/feeds install -a

Select the router architecture, model and the needed packages in menuconfig.

    make menuconfig

We suggest you to deselect the package _dnsmasq_ from _Base system_ section and
to select _dnsmasq-dhcpv6_ in the same section. Then to deselect _odhcpd_ from
_Network_ section.

Finally enter the _LiMe_ section and select the wanted LibreMesh features.

Compile the firmware images.

    make

The resulting files will be present in _bin_ directory.

## Testing

LibreMesh has unit tests that help us add new features while keeping maintenance effort contained.

To run the tests simply execute `./run_tests`.

Please read the [[Unit Testing Guide](TESTING.md)] for more details about testing and how to add tests to LibreMesh.

## Get in Touch with LibreMesh Community

### Mailing Lists

The project offers the following mailing lists

- [lime-dev@lists.libremesh.org][7] - This list is used for general development
  related work.
- [lime-users@lists.libremesh.org][8] - This list is used for project
  organisational purposes. And for user specific questions.

### Contributors

This project exists thanks to all the people who contribute. [[Contribute](CONTRIBUTING.md)].
<a href="https://github.com/libremesh/lime-packages/graphs/contributors"><img src="https://opencollective.com/libremesh/contributors.svg?width=890&button=false" /></a>


### Donations

We are now a member of [open collective][12], please consider a small donation!

#### Backers

Thank you to all our backers! 🙏 [[Become a backer](https://opencollective.com/libremesh#backer)]

<a href="https://opencollective.com/libremesh#backers" target="_blank"><img src="https://opencollective.com/libremesh/backers.svg?width=890"></a>


#### Sponsors

Support this project by becoming a sponsor. Your logo will show up here with a link to your website. [[Become a sponsor](https://opencollective.com/libremesh#sponsor)]

<a href="https://opencollective.com/libremesh/sponsor/0/website" target="_blank"><img src="https://opencollective.com/libremesh/sponsor/0/avatar.svg"></a>
<a href="https://opencollective.com/libremesh/sponsor/1/website" target="_blank"><img src="https://opencollective.com/libremesh/sponsor/1/avatar.svg"></a>
<a href="https://opencollective.com/libremesh/sponsor/2/website" target="_blank"><img src="https://opencollective.com/libremesh/sponsor/2/avatar.svg"></a>
<a href="https://opencollective.com/libremesh/sponsor/3/website" target="_blank"><img src="https://opencollective.com/libremesh/sponsor/3/avatar.svg"></a>
<a href="https://opencollective.com/libremesh/sponsor/4/website" target="_blank"><img src="https://opencollective.com/libremesh/sponsor/4/avatar.svg"></a>
<a href="https://opencollective.com/libremesh/sponsor/5/website" target="_blank"><img src="https://opencollective.com/libremesh/sponsor/5/avatar.svg"></a>
<a href="https://opencollective.com/libremesh/sponsor/6/website" target="_blank"><img src="https://opencollective.com/libremesh/sponsor/6/avatar.svg"></a>
<a href="https://opencollective.com/libremesh/sponsor/7/website" target="_blank"><img src="https://opencollective.com/libremesh/sponsor/7/avatar.svg"></a>
<a href="https://opencollective.com/libremesh/sponsor/8/website" target="_blank"><img src="https://opencollective.com/libremesh/sponsor/8/avatar.svg"></a>
<a href="https://opencollective.com/libremesh/sponsor/9/website" target="_blank"><img src="https://opencollective.com/libremesh/sponsor/9/avatar.svg"></a>

[1]: https://openwrt.org/docs/guide-developer/quickstart-build-images
[2]: https://github.com/libremesh/lime-sdk
[4]: http://libremesh.org/howitworks.html
[5]: http://libremesh.org/
[7]: https://lists.libremesh.org/mailman/listinfo/lime-dev
[8]: https://lists.libremesh.org/mailman/listinfo/lime-users
[9]: http://repo.libremesh.org/current/
[10]: https://github.com/libremesh/network-profiles/
[11]: https://chef.libremesh.org/
[12]: https://opencollective.com/libremesh






