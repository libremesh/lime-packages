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

## Command line

`epoc` is expressed in [Unix Timestamp](https://en.wikipedia.org/wiki/Unix_time) format. You can use a tool like [unixtimestamp.com](https://www.unixtimestamp.com/) to get a date in the correct format.

### `captive_portal status`

Prints the status of pirania: enabled or disabled.

### `captive_portal start`

Starts pirania. If you want pirania to automatically turn on use: `uci set pirania.base_config.enabled=1 && uci commit`

### `captive_portal stop`

Stops pirania. If you want pirania to stop automatically turning on use: `uci set pirania.base_config.enabled=0 && uci commit`

### `voucher list_vouchers`

Returns a json list of all vouchers in pirania database.

### `voucher print_valid_macs`

Lists the mac addresses of all devices using a non-expired voucher

### `voucher add_voucher`

Adds a single voucher to pirania database.

Params:
- `key`: a name used to identify the voucher
- `voucher`: voucher secret
- `epoc`: date (unix time) that the voucher will expire
- `upload`: upload limit for this voucher 0 to 10
- `download`: download limit for this voucher 0 to 10
- `amountofmacsallowed`: amount of devices that can use this voucher

Ex.: `voucher add_voucher my-voucher-name voucher-secret 1619126965 10 10 1`

#### `voucher auth_voucher`

Authenticates a mac address with a voucher.

Params:
- `mac`: a device's mac address
- `voucher`: secret for a voucher

Ex.: `voucher auth_voucher voucher-secret d0:82:7a:49:e2:37`

### `voucher remove_voucher`

Invalidates a voucher by changing it's expire date to 0.

Params:
- `voucher`: voucher secret

Ex.: `voucher remove_voucher voucher-secret`

### `voucher voucher_status`

Shows the voucher status for a specific mac address.

Params:
- `mac`: a device's mac address

Ex.: `voucher voucher_status d0:82:7a:49:e2:37`

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

    /etc/shared-state/publishers/shared-state-publish_vouchers inserts into shared-state the local voucher db
    /etc/shared-state/hooks/pirania/generate_vouchers bring updated or new vouchers from the shared-state database into the local voucher db
```

### Trafic capture
`/usr/bin/captive-portal` sets up iptables rules to capture traffic.
It creates a set of rules that apply to 3 allowed "ipsets":
* pirania-auth-macs: authorized macs go into this rule. starts empty.
* pirania-allowlist-ipv4: with the members of the allowlist in the config file (10.0.0.0/8, 192.168.0.0/16, 172.16.0.0/12)
* pirania-allowlist-ipv6: same as ipv4 but for ipv6

Rules:
* DNS packets, that are not from the allowed ipsets, are redirected to our own captive portal DNS at 59053
* HTTP packets, that are not from the allowed ipsets, are redirected to our own captive portal HTTP at 59080
* packets from the allowed ipsets are allowed
* the rest of the packets are rejeted (drop and send an error to the client)

### HTTP flow

`/etc/init.d/pirania-uhttpd` starts a HTTP server (uhttpd) on port 59080 that replies any request with a redirect towards a preset URL (`pirania.base_config.portal_url`). This is performed by the lua script `/www/pirania-redirect/redirect`. As `pirania.base_config.portal_url` is in the allowlist ip range (http://thisnode.info/portal/ by default) then the "normal" HTTP server listening in port 80 will answer after the redirect.

So the flow is:
* navigate to a non allowed ip: for example `http://orignal.org/baz/?foo=bar`
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

### TODO

* Update rpcd interface
* Expose the voucher creation with duration functionality
* Add renew functionality
* Have a "emergency" function to force pirania to show for everyone
* Improveportal HTML/js actions
* Fix redirect to the "original site", now goes to for example /cgi-bin/pirania/http%3A%2F%2Fprueba.com%2F
* Do not re-add removed vouchers from the shared-state db (see removed.txt).
