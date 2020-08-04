![PIRANHA](https://i.imgur.com/kHWUNOu.png)

## Voucher and Captive Portal solution for community networks

This tool allows an administrator to manage a voucher system to get through the gateway.

It could be used in a community that wants to share an Internet connection and for that the user's pay a fraction each, but needs the payment from everyone. So the vouchers allows to control the payments via the control of the access to Internet.

## Features

This are the currently implemented features:
  * Runs directly from the OpenWRT/LEDE router: no need for extra hardware
  * Integrates it's administration with Ubus and LiMe App
  * Has a command-line interface for listing, creating and removing vouchers
  * Voucher database is shared among nodes in the network

## Prerequisites

This software assumes that will be running on a OpenWRT/LEDE distribution (because uses uci for config). Needs `ip6tables-mod-nat` and `ipset` packages installed.

## Install

  * add the libremesh software feed to opkg
  * opkg install pirania
  * opkg install pirania-app

# How it works

It uses iptables rules to filter inbound connections outside the mesh network.

## General overview of file hierarchy and function

```
files/
    /etc/config/pirania is the UCI config
    /etc/pirania/vouchers/ (default path) contains the database of vouchers
    /etc/init.d/pirania-uhttpd starts a uhttpd on port 59080 that replies any request with a redirect towards a preset URL

    /usr/lib/lua/voucher/ contains lua libraries used by /usr/bin/voucher
    /usr/bin/voucher is a CLI to manage the db (has functions show, show_active, show_authorized_macs, add, activate, deactivate and is_mac_authorized)
    /usr/bin/captive-portal sets up iptables rules to capture traffic

    /usr/libexec/rpcd/pirania ubus pirania API (this is used by the web frontend)
    /usr/share/rpcd/acl.d/pirania.json ACL for the ubus pirania API
```

### Trafic capture
`/usr/bin/captive-portal` sets up iptables rules to capture traffic.
It creates a set of rules that apply to 3 allowed "ipsets":
* pirania-auth-macs: authorized macs go into this rule. starts empty.
* pirania-whitelist-ipv4: with the members of the whitelist in the config file (10.0.0.0/8, 192.168.0.0/16, 172.16.0.0/12)
* pirania-whitelist-ipv6: same as ipv4 but for ipv6

Rules:
* DNS packets, that are not from the allowed ipsets, are redirected to our own captive portal DNS at 59053
* HTTP packets, that are not from the allowed ipsets, are redirected to our own captive portal HTTP at 59080
* packets from the allowed ipsets are allowed
* the rest of the packets are rejeted (drop and send an error to the client)

### HTTP flow

`/etc/init.d/pirania-uhttpd` starts a HTTP server (uhttpd) on port 59080 that replies any request with a redirect towards a preset URL (`pirania.base_config.portal_url`). This is performed by the lua script `/www/pirania-redirect/redirect`. As `pirania.base_config.portal_url` is in the whitelisted ip range (http://thisnode.info/portal/ by default) then the "normal" HTTP server listening in port 80 will answer after the redirect.

So the flow is:
* navigate to a non whitelisted ip: for example `http://orignal.org/baz/?foo=bar`
* get redirected with a 302 where you can put a voucher code to enter: `http://thisnode.info/cgi-bin/portal/auth.html?prev=http%3A%2F%2Foriginal.org%2Fbaz%2F%3Ffoo%3Dbar`
* submiting the form should perform a GET to `http://thisnode.info/cgi-bin/pirania/preactivate_voucher?voucher=secretcode&prev=http%3A%2F%2Foriginal.org%2Fbaz%2F%3Ffoo%3Dbar`
* The preactivate_voucher script does two different depending on javascript support:
    * If nojs=true then the voucher is activated with the client MAC (taken from the ARP table with its IP) and the voucher code. If the activation succeeds it redirects to `url_authenticated`.
    * If nojs=false there is a check if the voucher code would be valid (there is an unused and valid voucher with that code). If the voucher would be valid then a redirect to the portal INFO page(`pirania.base_config.url_info`) is performed with the voucher code as param url. The portal info shows the updated information of the community and there is a time that you have to wait to be able to continue (This is done with JS). When the timer reaches 0 you can click in continue. This redirects now to `http://thisnode.info/cgi-bin/pirania/activate_voucher?voucher=secretcode`. The `activate_voucher` script does the voucher activation. then it redirects to `url_authenticated`. If the code fails it will redirect to `http://thisnode.info/cgi-bin/portal/fail.html` that is identical to auth.html but with an error message.

### ubus API

* enable() -> calls to `captive-portal start` and enables it in the config
* disable() -> calls to `captive-portal stop` and disables it in the config
* show_url() -> return config `pirania.base_config.portal_url`
* change_url(url) -> change config `pirania.base_config.portal_url`
* ...

### CLI

```
$ voucher show
$ voucher add san-notebook mysecret $((`date +%s` + 1000))
ok
$ voucher show
san-notebook	mysecret	xx:xx:xx:xx:xx:xx	Tue Aug  4 02:45:01 2020
$ voucher show_active
$ voucher activate mysecret 00:11:22:33:44:55
$ voucher show
san-notebook	mysecret	00:11:22:33:44:55	Tue Aug  4 02:45:01 2020

$ voucher show_active
san-notebook	mysecret	00:11:22:33:44:55	Tue Aug  4 02:45:01 2020

$ vouchervoucher deactivate san-notebook
ok
$ vouchervoucher show_active
$ vouchervoucher show
san-notebook	mysecret	00:11:22:33:44:55	Thu Jan  1 00:00:00 1970
```
