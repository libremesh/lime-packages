All notable changes to this project will be documented in this file.

## 2023.1 - Unreleased

### Full changelog since 2023.1-rc2

  - Use SPDX License Identifier to shrink size (merge [#1018](https://github.com/libremesh/lime-packages/pull/1018)) 
  - Small cleaning (merge [#1037](https://github.com/libremesh/lime-packages/pull/1037))
  - Add new reference state data types to shared state (merge [#1042](https://github.com/libremesh/lime-packages/pull/1042))


## 2023.1-rc2 - Release candidate 2 - 17 sep '23

### Full changelog since 2023.1-rc1
  - Fix safe-upgrade bootstrap broken since OpenWrt 19.07 (merge #1050)
  - Add force option to safe-upgrade bootstrap cmd (merge #1051)
  - Default distance setting: increase 10x (merge #1047)
  - add wifi interface name in shared state wifi information module (merge #1048) 
  - add freq information (merge #1045) 
  - Enable Node Information Exchange (merge #1043)
  - readme: expanded instructions on ImageBuilder (merge #1028)
  - removed extra info from shared state (merge #1041) 
  - wifi-unstuck-wa: allow parametrizable values for interval and timeout (merge #1039, fix #1034) 
  - Shared state ubus (merge #1040)
  - New Shared-State wifi Links information module (merge #1038)

## 2023.1-rc1 - Release candidate 1 - 5 aug '23

### Full changelog
  - Add shared state async node (merge #1030)
  - lime.network.scandevices: fix finding intefaces on dsa devices (merge #1033) 
  - Unit testing update (merge #1027)
  - various readme improvements (merge #1015)
  - remove old iw/iw-full compatibility check (merge #1024)
  - angw, lime-proto-bmx7: use nft includes instead of init.d scripts (merge #1021)
  - Remove iputils-ping retrocompatibility with OpenWrt 19.07 (merge #999, fix #794)
  - random-numgen: set PKGARCH:=all (merge #1017)
  - Updated lime-example to follow lime-defaults (merge #1001)
  - Adding the random-numgen command and use it for removing usage of $RANDOM (merge #991, fix #800)
  - Fix category of shared-state-dnsmasq_servers (merge #994)
  - Added a few commands to lime-report (merge #1005)
  - lime-debug added iperf3 and jq (merge #1011)
  - Batman-adv add the orig_interval to the lime-* config files and set a larger default value (merge #1013, fix #1010)
  - Batman-adv allow the user to set the routing_algo (merge #1014)
  - shared-state-dnsmasq_servers correct serversfile option setting (merge #1004, partial fix #970)
  - lime-proto-batadv remove retrocompatibility (merge #1012)
  - Fix category of babled-auto-gw-mode (merge #1006, fix #996)
  - Move safe reboot to admin protected function (merge #989, fix #909)
  - Split network.lua's owrt_ifname_parser (merge #998)
  - Expose get_loss (merge #978)
  - Port libremesh to fw4 and nftables (merge #990)
  - shared-state-dnsmasq_servers: new package (merge #812)
  - Improve get node status results (merge #974)
  - lime-proto-babeld: enable ubus bindings (merge #987)
  - ubus-lime-utils place scripts in /etc/udhcpc.user.d/ (merge #950, fix #927)
  - Replace OpenWrt 19.07 switch config style with OpenWrt 21.02 one in proto-lan and network.lua's device parser (merge #959)

## 2020.4 Expansive Emancipation - 17 sep '23

### Full changelog
- default distance setting increase 10x 


## 2020.3 Expansive Emancipation - 21 apr '23

### Release notes
List of notable changes since 2020.1:
- the support for OpenWrt 18.06 has been dropped
- lime-app has been updated from 0.2.9 to 0.2.25
- babeld-auto-gw-mode replaces batman-adv-auto-gw-mode for automatically deactivating gateways with no working internet connection (for network with more than one internet-sharing nodes)
- the wifi configuration has been split in 2ghz and 5ghz bands sections
- many new Prometheus exporters for more detailed monitoring of the nodes' status
- many minor fixes

Thanks to all the people who contributed to the lime-packages repository:
a-gave, Aman, AngiieOG, Brad, Daniel Golle, elián l, Frank95, FreifunkUFO, G10h4ck, gabri94, Germán Ferrero, Gui Iribarren, hiure, Humz, Ilario Gelmetti, itec, Jess, Juli, juliana, leonaard, Luandro, Marcos Gutierrez, meskio, Michael Jones, Micha Stöcker, Mike Russell, nicoechaniz, Nicolás Pace, p4u, PatoGit, Pau Escrich, Paul Spooren, Pedro Mauro, pony1k, radikal, Rohan Sharma, San Piccinini, selankon, valo, Vittorio Cuculo

Specifically, the ones who contributed to the changes from 2020.1 to 2020.3:
a-gave, altergui, aparcar, dangowrt, G10h4ck, germanferrero, ilario, itec78, julianaguerra, luandro, meskio, nicopace, pony1k, RhnSharma, selankon, spiccinini

Also, a priceless contribution came from the LibreMesh users who shared their experience commenting on the open tickets on Github, in the chat and in the mailing list!

### Full changelog
  - adujst lime_release and lime_codename

## 2020.2 Expansive Emancipation - 20 mar '23

### Full changelog
  - Check for /etc/init.d/odhcpd existence before executing (merge #982, fix #954)
  - shared-state check for babeld file existence before reading it (merge #983)
  - check-date-http improve error handling (merge #981, fix #723)
  - shared-state get neigh avoid outputting empty lines (merge #984)
  - dnsmasq move confdir setting for ujail, avoiding to fix batman-adv-auto-gw-mode (merge #979, fix #970)
  - shared-state-publish_dnsmasq_leases recognize IPv6 when IPv6 leases are present (merge #975, fix #969)
  - unstuck-wifi: send SIGTERM to iw-processes still running after 5 minutes (merge #966, fix #964)
  - Add meuno.info to anygw for portuguese acessibility (merge #973)
  - Fix/lime utils issue (merge #963, fix #962) 
  - lime-app: update title in lime-app (merge #926)
  - Fixing some dependencies (merge #941)
  - Feature/split lime metrics logic (merge #937)
  - Feature/split lime utils logic (merge #939)
  - migrate-wifi-bands-cfg check for conf files being existing (merge #947, fix #945)
  - network.lua use an alternate string if ifname is not found by owrt_device_parser (merge #948, fix #944)
  - Removal of packages with non-existing dependencies (merge #943, fix #929)
  - Feature/fbw verbose scanning (merge #925)
  - Relax switch vlan filter (merge #900)
  - Readme: updated mailing list direction (merge #931)
  - shared-state: provide compressed cgi-bin endpoints (merge #911)
  - Refactor/fbw new structure (merge #923)
  - p-n-e-l: avoid underscore in package names (merge #922)
  - pirania: preserve config on upgrade (merge #921)
  - Lime app to version v0.2.25 (merge #918)
  - Add client hotspot wwan connection handling (merge #890)
  - wireless-service: fix ubus enpoint name (merge #914)
  - keep.d: add banner.notes (merge #915)
  - watchping: change starting value for last_hook_run (merge #910)
  - location: fix set() inserting bad data to shared-state (merge #908)
  - Pirania new API (merge #893)
  - lime-proto-anygw: use the configured domain as a hostrecord (merge #906)
  - Allow changing wifi password (#901)
  - fbw: use a more permisive temporary wifi config (merge #859)
  - lime-webui add dependency from luci-compat (merge #899)
  - fbw: add optional country config (merge #843)
  - Add feature mac-based config file (merge #883)
  - Migrate frequency band suffix options to uci sections for each band (merge #896)
  - prometheus-node-push-influx: new package (merge #871)
  - Pirania rcpd api fixes and improvements (merge #892)
  - add tail command to remove first character of the string (merge #891, fix #888)
  - Add shared state network nodes (merge #873, fix #867)
  - Refactor Pirania simplifying its code and fixing bugs (merge #869)
  - Add shared state multiwriter (merge #872, fix #868)
  - Fix tmate black screen when joining (merge #885)
  - lime-system: flush autogen before modifying it (merge #882)
  - lime-location: keep the location settings (merge #881)
  - LimeApp updated to v0.2.20 (merge #880)
  - lime-utils-admin: add firmware upload acl permission (merge #879)
  - Qemu 12 nodes in 4 different clouds (merge #813)
  - Pirania cli explanations on README (merge #865)
  - LimeApp updated to v0.2.16 (merge #858)
  - lime-utils: on upgrade preserve configs by default (merge #857)
  - Fix shared state location publisher (merge #854)
  - fbw: support community lime-assets (merge #852, fix #846)
  - shared-state-bat_hosts: mv acl file to the correct directory (merge #851, fix #850)
  - Fix some missing dependencies (merge #847)
  - RFC add babeld-auto-gw-mode (merge #844)
  - LimeApp updated to v0.2.15 (merge #840)
  - Shared state improvements (merge #841)
  - Add ubus-tmate to expose tmate control for terminal sharing (merge #839)
  - Refactor libremesh.mk and makefiles (merge #829, fix #825)
  - Lime proto babeld fixes (merge #830)
  - Add unittests with coverage to GitHub-CI (merge #836)
  - shared-state: multiple fixes (merge #823)
  - lime-proto-batadv change MAC also of wlan interfaces (merge #820)
  - Refactor lime location as lib and fix location shared state publishing (merge #834)
  - Fix pirania missing dependency on shared-state-pirania (merge #811)
  - shared-state: parse babeld.conf interfaces in get_candidates_neigh (merge #831)
  - lime-utils: remove debugging print (merge #832)
  - Add lua remote debugging instructions (merge #828)
  - Update readme (merge #827)

## 2020.1 Expansive Emancipation - 14 dic '20

### Release notes
The LibreMesh team is happy to announce a new version of LibreMesh, 2020.1 "ExpansiveEmancipation". 
Three years of work, 882 commits, 23 developers, tons of bug fixes and improvements!

This release is compatible with OpenWrt stable 19.07.5 and old-stable 18.06.9. 
For the time  source-only release so you will need compile it yourself for the devices used by your community using the easy to follow instructions in https://libremesh.org/development.html

#### What's in 2020.1 "Expansive Emancipation"
It is imposible to do a meaninful list of all the changes. A non complete list of the most relevant developments:
* LimeApp: an app to for the maintenance and deploy of community networks targeted to non-technical community members. https://github.com/libremesh/lime-app/
* A new community-oriented configuration system that facilitates collective maintenance of configurations.
* shared-state, a shared database for the network.
* first-boot-wizard, an optional helper to deploy and extend the network that it is well integrated with the LimeApp.
* Pirania, an optional boucher and captive portal solution for community networks https://github.com/libremesh/lime-packages/blob/master/packages/pirania/Readme.md
* Hundreds of fixes and code improvement.

#### Contributors
This release has contributions from communities and individuals from all around the world. Testing, software development, documentation, community building. Thank you all!!

A list of the software developers that contributed to this release was easily gathered from the git history: AngiieOG, Brad, Daniel Golle, FreifunkUFO, German Ferrero, Gioacchino Mazzurco, Gui Iribarren, Ilario Gelmetti, Jess, Luandro, Marcos Gutierrez, Michael Jones, Mike Russell, Nicolás Pace, PatoGit, Pau, Paul Spooren, Pedro Mauro, Santiago Piccinini, Vittorio Cuculo, hiure, radikalbjr, valo.


## 17.06 Dayboot Rely - 23 sep '17

### Release notes
So, this release was meant to be announced many months ago (as the
numbering suggests) but lack of coordination (me, gio, pau) delayed it.
In the meantime, some more fixes and improvements were introduced, and
most importantly, several (unpublished) intermediate "release
candidates" have been running for months now, in different community
networks (QuintanaLibre mainly, thanks to persevering NicoEchaniz, and
other smaller deployments)

Highlights are that ieee80211s is used by default (instead of adhoc)
which breaks "backward" connectivity with previous releases,
as well as changes in vlan tagging policy of bmx6 and batadv (which also
are not backwards compatible by default)
most notably, this vlan change fixes a hard-to-debug mtu shrinking bug
that pestered all releases so far (symptoms were varied and bizarre,
like having timeouts when trying to browse certain https sites,
sometimes, on random devices)
the biggest highlight on the dev side, is that we now use upstream SDK
(thanks to dangowrt for pushing this, and pau for implementing it!)
which brings us much closer to LEDE/OpenWrt and allows reporting
upstream ath9k bugs or such, among other benefits

* generic binaries, meant for testing or setting up temporary networks
  (i.e. when having the default AP SSID = LibreMesh.org is fine)

http://downloads.libremesh.org/dayboot_rely/17.06/targets/

(build is running right now, binaries should be ready tomorrow for sure)

* for custom builds, the recommended tool at this point is lime-sdk

http://libremesh.org/getit.html#cook_your_own_firmware_using_lime_sdk
https://github.com/libremesh/lime-sdk

* chef builds are not available at this point. there are plans to
integrate this release into chef in the future, but no ETA 🙁

Most of the following changelog was accomplished during the 2017/03
hackaton (https://www.youtube.com/watch?v=5UX1FwhIKGY)

Additional source: http://es.wiki.guifi.net/wiki/LibreMesh/Changelog

### Full changelog
Changelog since 16.07 Community Chaos

  * based on LEDE 17.01.2
  * build everything using LEDE SDK, via new lime-sdk cooker (instead of
lime-build)
  * use ieee80211s instead of adhoc
  * reintroduced "firewall" package (to keep closer to upstream)
  * lime-system: fix ieee80211s proto, correctly construct ifnames
  * lime-system: sanitize hostname (transform everything into
alphanumeric and dash)
  * lime-system: new proto static
  * lime-system: new wifi mode client
  * lime-system: set dnsmasq force=1 to ensure dnsmasq never bails out
  * lime-system: explicitly populate /etc/config/lime with calculated values
  * lime-webui: enable i18n, finally webinterface is available in Spanish
  * lime-webui: Major rework by NicoPace, thanks!
    * bmx6 node graph now uses colors in a clever way
    * simple way to add "system notes" that are shown along with
/etc/banner and webui
    * luci-app-lime-location: fix google maps api key
    * new read-only view: switch ports status
    * alert luci-mod-admin users that their changes might get
overwritten by lime-config
    * fix batman-adv status webui
  * new package available to install lighttpd instead of uhttpd (needed
for an upcoming android app)
  * added a lime-sysupgrade command: does a sysupgrade but only
preserving libremesh configuration file
  * added a lime-apply command: basically calls reload_config, but also
applies hostname system-wide without rebooting
  * lime-hwd-ground-routing: ground routing now supports untagged ports too
  * lime-proto-anygw: unique mac based on ap_ssid (using %N1, %N2)
  * lime-proto-anygw: integrate better into /etc/config/dhcp instead of
/etc/dnsmasq.d/
  * lime-proto-wan: allow link-local traffic over wan (useful for local
ping6 and ssh, without global exposure)
  * lime-proto-batadv: set batadv gw_mode=client by default to
counteract rogue DHCP servers
  * lime-proto-bmx6: introduce bmx6_pref_gw option, adds priority (x10)
to a specific bmx6 gateway
  * lime-proto-bmx6: don't tag bmx6 packets over ethernet and so use at
least mtu=1500 everywhere
  * lime-proto-bmx6: avoid autodetected wan interface use vlan for bmx6
  * bmx6: doesn't flood log with some spurious warnings anymore (syslog=0)
  * bmx6: sms plugin now enabled by default
  * bmx6: daemon is now supervised by procd, so it is restarted in case
of crashes
  * bmx6: doesn't "configSync" by default anymore (no more "uci pending
changes" because of auto-gw-mode)
  * new bmx6hosts tool: maintain an /etc/hosts that resolves fd66: <->
hostnames.mesh
  * watchping: convert to procd and add reload triggers
  * safe-reboot: fix, use /overlay/upper instead of /overlay
  * safe-reboot: add "discard" action
  * ath9k: debugged some hangs (interface is deaf) and workaround it,
with new package "smonit"
  * set wifi default "distance" parameter to 1000 metres and make it
configurable through webui
  * alfred: fix bat-hosts facter, check for errors and don't nuke
/etc/bat-hosts in case of failure
  * introduce new lime-basic-noui metapackage
  * new packages separated: lime-docs and lime-docs-minimal
  * various Makefile dependency problems fixed

known bugs:
  * safe-reboot: newly introduced "discard" action is half-baked, avoid
usage until next release:
    It doesn't check whether there's a backup to restore or not -
https://github.com/libremesh/lime-packages/issues/203
    so executing "safe-reboot discard" without having done "safe-reboot"
first, will brick the router.
    (unbricking is possible via failsafe boot, and doing "mount_root &&
firstboot")

In the commit log authors you can see the usual suspects 😉
but happily many new names!
https://github.com/libremesh/lime-packages/graphs/contributors?from=2016-09-08&to=2017-09-23&type=c

and remember it's not only code/commits what matters, so big thanks as
well to everyone participating in mailing lists, maintaining website,
documentation (spread around the web, in many languages!)


## 16.07 Community Chaos - 8 sep '16

### Release notes
Thanks to everyone involved, finally we have an official release!
* generic binaries, meant for testing or setting up temporary networks
   (i.e. when having the default AP SSID = LibreMesh.org is fine)

http://downloads.libremesh.org/community_chaos/16.07/

* customized binaries with chef, meant for stable community networks
   (basically, you can preset a specific AP SSID and other settings
   common to the whole network, and then flash many routers in a row)
   can be generated at:

http://chef.libremesh.org/

### Full changelog 
Changelog since "BiggestBang" 15.09:
  * Now based on OpenWrt Chaos Calmer 15.05.1
  * Removed "firewall" package (which is included by default in vanilla
  OpenWrt/LEDE), since it's not really being used in LibreMesh setup. It
  can always be installed on a case-by-case basis using opkg.
    * there's a new minimal system that runs /etc/firewall.lime on boot
  (if "firewall" is not installed)
  * Removed "odhcpd" since we're not using it at the moment (we use dnsmasq)
  * Removed "odhcp6c" since we're not using it at the moment (we still
  haven't solved how to deal with native IPv6 coming over WAN, i.e.
  propagate a delegated prefix over the mesh in a reasonable way)
  * New default packages: "lime-hwd-openwrt-wan" and "lime-proto-wan".
  This checks if there's a WAN port, and automatically configures as "wan"
  proto (lime-proto-wan). The "wan" proto let's you assign in
  /etc/config/lime, for example, 802.1ad VLANs over the WAN port.
  * New default package: "lime-hwd-ground-routing". Allows you to
  configure 802.1q VLANs on embedded switches, so that you can separate
  specific ports and put
  * New default package: "bmx6-auto-gw-mode", so that when a node detects
  (with watchping) it can ping 8.8.8.8 over WAN port, a bmx6 tunIn is
  created on-the-fly, and Internet is shared to the rest of the clouds.
  * Workaround for an spurious log message caused by BATMAN-Adv ("br-lan:
  received packet on bat0 with own address as source address"): a "dummy0"
  interface is created and added to bat0, with a slightly different MAC
  address
    * https://lists.open-mesh.org/pipermail/b.a.t.m.a.n/2014-March/011839.html
  * New available packages: "lime-proto-bgp", allows to do BGP with bird
  daemon; and "lime-proto-olsr", "-olsr2" and "-olsr6", which add support
  for all versions of OLSR.
  * Some new settings possible in /etc/config/lime-defaults
    * wireless.htmode lets you preset the htmode for any wireless radio
  (or htmode_2ghz and htmode_5ghz for specific bands)
    * wireless.distance is the equivalent, for setting distance (and
  distance_2ghz / _5ghz)
    * system.domain for setting a cloud-wide domain name
  * New "named AP" interface by default: in addition to the shared SSID
  (where clients roam between nodes), there's a new AP with a different,
  unique SSID (it includes the node hostname). This lets people easily
  check with any stock smartphone (not only Android with a special app)
  which nodes are online, nearby, and their respective signal strength.
  Most importantly, it lets them connect to a specific AP and prevent
  roaming, when they need it. Roaming is a nuisance if you're in the
  middle of two nodes, with similar RSSI, but different performance
  (bandwidth to Internet). Finally, it gives users a very easy way to
  reliably access a specific (nearby) node webinterface, simply
  associating to a specific AP and browsing to http://thisnode.info/
  * Fixed all alfred facters (bat-hosts, dnsmasq-distributed-hosts,
  dnsmasq-lease-share), so that they retry the "alfred -r" when it fails
  (i.e. in slave mode)
  * LiMe web interface received love:
    * luci-app-lime-location (Simple Config -> Location) now works
    * Simple Config -> Advanced


