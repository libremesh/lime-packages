[![Backers on Open Collective](https://opencollective.com/libremesh/backers/badge.svg)](#backers) 
[![Sponsors on Open Collective](https://opencollective.com/libremesh/sponsors/badge.svg)](#sponsors) 
[![codecov.io](http://codecov.io/github/libremesh/lime-packages/branch/master/graphs/badge.svg)](http://codecov.io/github/libremesh/lime-packages)

# [LibreMesh][5] packages

[![LibreMesh logo](https://raw.githubusercontent.com/libremesh/lime-web/master/logo/logo.png)](https://libremesh.org)

[LibreMesh project][5] includes the development of several tools used for
deploying libre/free mesh networks.

The firmware (the main piece) will allow simple deployment of auto-configurable,
yet versatile, multi-radio mesh networks. Check the [Network Architecture][4] to
see the basic ideas.

We encourage each network community to create its firmware profile on
[network-profiles][10] repository and build the images locally.


## Supported hardware

[In this page][1] we provide a list of requirements that ensure you to have a
working LibreMesh node on your router. This list comes with no warranties: read
carefully the [model-specific instructions on OpenWrt wiki][OpenWrt-ToH] and be
extra-careful when flashing your routers!

## Building a Firmware Image on Your PC

### Building the stable release LibreMesh 2020.1

#### Using the BuildRoot

The BuildRoot **will cross-compile the whole OpenWrt and the LibreMesh packages** on your computer, so it will take approx 10 GB of disk space and a few hours of compilation time.

For compiling LibreMesh firmware with this method, you can follow [these instructions][development_page].

#### Using the ImageBuilder

The ImageBuilder method is not available for the stable release.

### Building the experimental firmware

The experimental code still has serious issues that have to be solved, use it only for developing or debugging.

#### Using the BuildRoot

As explained above, in the instuctions on the website you will find where to specify the version of the code to compile.

#### Using the ImageBuilder

The ImageBuiler **will download pre-compiled parts of the OpenWrt releases**, and add the pre-compiled LibreMesh packages, so it is **much faster** than the BuildRoot method (but less practical if you want to develop some new features modifying LibreMesh source code).

Start an ImageBuilder of your choice, for example ath79-generic if your device is supported within it, use containers for an easier setup:

```shell
mkdir ./images/
docker run -it -v $(pwd)/images:/images/ ghcr.io/openwrt/imagebuilder:ath79-generic-v22.03.5
```

If your device is not part of ath79-generic profiles, you can replace it with another <target>-<subtarget> combination. For knowing which target and subtarget is best suited for your router, check out the page about it in the [OpenWrt's Table of Hardware][OpenWrt-ToH].

Within the container, add the `lime-packages` feed:

```shell
echo "src/gz libremesh https://feed.libremesh.org/master" >> repositories.conf
echo  "untrusted comment: signed by libremesh.org key a71b3c8285abd28b" > keys/a71b3c8285abd28b
echo "RWSnGzyChavSiyQ+vLk3x7F0NqcLa4kKyXCdriThMhO78ldHgxGljM/8" >> keys/a71b3c8285abd28b
```

Ideally add your own `lime-community` files within the container in the folder
`./files/etc/config/`. To find possible options consult the
[lime-example.txt][lime-example] file. It is also possible to mount an existing
`lime-community` file directly via `-v
$(pwd)/lime-community:/builder/files/etc/config/lime-community`.

Now create an image of your choice, to see the names of supported profiles run
`make info` first.

```shell
make image PROFILE=ubnt_unifi PACKAGES="lime-system lime-proto-babeld lime-proto-batadv lime-proto-anygw lime-hwd-openwrt-wan -dnsmasq" BIN_DIR=/images FILES=files
```

Your images should be available outside of the container in the `./images/` folder

##### Possible errors from the ImageBuilder

If you get a `docker: Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?.` error, means that you don't have Docker's daemon running. Make sure you have `docker` installed and start its daemon with `systemctl start docker.service`.

If you get a `opkg_download: Check your network settings and connectivity.` error, both check the connectivity and make sure that the firewall rules of your computer allow the container to reach the internet.


## Testing

LibreMesh has unit tests that help us add new features while keeping maintenance
effort contained.

To run the tests simply execute `./run_tests`.

Please read the [[Unit Testing Guide](TESTING.md)] for more details about
testing and how to add tests to LibreMesh.

## Get in Touch with LibreMesh Community

### Mailing Lists

The project has an official mailing list [libremesh@krutt.org][8] and an Element
(#libremesh-dev:matrix.guifi.net) chat room; check out [this page][9] with the
links for joining the chatroom.


### Contributors

This project exists thanks to all the people who contribute. [[Contribute](CONTRIBUTING.md)].
<a href="https://github.com/libremesh/lime-packages/graphs/contributors"><img src="https://opencollective.com/libremesh/contributors.svg?width=890&button=false" /></a>


### Donations

We are now a member of [open collective][12], please consider a small donation!

#### Backers

Thank you to all our backers! 🙏 [[Become a
backer](https://opencollective.com/libremesh#backer)]

<a href="https://opencollective.com/libremesh#backers" target="_blank"><img src="https://opencollective.com/libremesh/backers.svg?width=890"></a>


#### Sponsors

Support this project by becoming a sponsor. Your logo will show up here with a
link to your website. [[Become a
sponsor](https://opencollective.com/libremesh#sponsor)]

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

[1]: https://libremesh.org/docs/hardware/
[OpenWrt-ToH]: https://openwrt.org/toh/start
[4]: https://libremesh.org/howitworks.html
[5]: https://libremesh.org/
[8]: https://www.autistici.org/mailman/listinfo/libremesh
[9]: https://libremesh.org/communication.html
[10]: https://github.com/libremesh/network-profiles/
[12]: https://opencollective.com/libremesh
[development_page]: https://libremesh.org/development.html

[lime-example]: https://github.com/libremesh/lime-packages/blob/master/packages/lime-docs/files/www/docs/lime-example.txt
