![PIRANHA](https://i.imgur.com/kHWUNOu.png)

## Voucher and Captive Portal solution for community networks

This tool allows an administrator to manage a voucher system to get through the gateway.

It could be used in a community that wants to share an Internet connection and for that the user's pay a fraction each, but needs the payment from everyone. So the vouchers allows to control the payments via the control of the access to Internet.

Additionally vouchers usage can be deactivated in order to use
the captive portal only to show valuable information for network
visitors.

## Features

These are the currently implemented features:
  * Runs directly from the OpenWrt router: no need for extra hardware
  * Integrates it's administration with Ubus and LiMe App
  * Has a command-line interface for listing, creating and removing vouchers
  * Voucher database is shared among nodes in the network
  * Portal "splash" screen content (logo, title, main text, etc)
  is distributed across the network.
  * Can be used without vouchers (read-for-access mode).
  * Tranca Redes: scheduled second-layer access control that restricts
  authorized MACs to specific destination categories during configured hours.

## Prerequisites

This software assumes that will be running on a OpenWrt distribution (because uses uci for config). Needs the `nftables` package installed (provides the `nft` command and kernel modules).

## Install

  * add the libremesh software feed to opkg
  * opkg install pirania

## Command line

`epoc` is expressed in [Unix Timestamp](https://en.wikipedia.org/wiki/Unix_time) format. You can use a tool like [unixtimestamp.com](https://www.unixtimestamp.com/) to get a date in the correct format.

### `captive-portal start`

Starts pirania. If you want pirania to automatically turn on use: `uci set pirania.base_config.enabled=1 && uci commit`

### `captive-portal stop`

Stops pirania. If you want pirania to stop automatically turning on use: `uci set pirania.base_config.enabled=0 && uci commit`

### `voucher list`

Lists all the vouchers.

### `voucher list_active`

List all the vouchers that are currently active.

### `voucher list_expired`

List all expired vouchers.

### `voucher list_available`

List all vouchers available for activation.

### `voucher add`

Create a new voucher. This voucher will start deactivated and not bonded to any device.

Params:
- `name`: a name used to identify the voucher
- `duration-m`: duration of the voucher in minutes. If no value is provided a permanent voucher will be created.
  The duration takes affect when the voucher is activated.
- `activation-deadline`: after this date (unix time) the voucher cannot be activated.

Flags:
- `--unrestricted` or `-u`: create an unrestricted voucher that bypasses Tranca Redes restrictions.
- `--duration` or `-d`: specify duration in minutes (alternative to positional arg).
- `--deadline`: specify activation deadline (alternative to positional arg).

To create a 60 minutes voucher:
`voucher add my-voucher-name 60`

To create an unrestricted permanent voucher:
`voucher add my-voucher-name --unrestricted`

### `voucher activate`

Activates a voucher, assigning a mac address. After the activation, the device with this MAC
address will have internet access.

Params:
- `secret-code`: the password of the voucher.
- `mac`: the MAC address of the device that will have access.

Ex: `voucher activate mysecret 00:11:22:33:44:55`

### `voucher deactivate`

Deactivate a voucher of the specified `ID`.

Params:
- `ID`: a string used to identify the voucher.

Ex: `voucher deactivate Qzt3WF`

### `voucher invalidate`

Invalidate a voucher (soft delete). The voucher remains in the database until pruned.

Params:
- `ID`: a string used to identify the voucher.

Ex: `voucher invalidate Qzt3WF`

### `voucher is_mac_authorized`

Check if a specific mac address is authorized.

Params:
- `mac`: a device's mac address

Ex: `voucher is_mac_authorized d0:82:7a:49:e2:37`

### `voucher show_authorized_macs`

Show MAC addresses of all currently active vouchers.

## CLI usage example

```
$ voucher list
$ voucher add san-notebook 60
Q3TJZS	san-notebook	ZRJUXN	xx:xx:xx:xx:xx:xx	Wed Sep  8 23:47:40 2021	60	           -            	1	normal
$ voucher list
Q3TJZS	san-notebook	ZRJUXN	xx:xx:xx:xx:xx:xx	Wed Sep  8 23:47:40 2021	60	           -            	1	normal
$ voucher list_active
$ voucher activate ZRJUXN 00:11:22:33:44:55
Voucher activated!
$ voucher list
Q3TJZS	san-notebook	ZRJUXN	00:11:22:33:44:55	Wed Sep  8 23:47:40 2021	60	Thu Sep  9 00:48:33 2021	2	normal

$ voucher list_active
Q3TJZS	san-notebook	ZRJUXN	00:11:22:33:44:55	Wed Sep  8 23:47:40 2021	60	Thu Sep  9 00:48:33 2021	2	normal

$ voucher deactivate Q3TJZS
ok
$ voucher list_active
$ voucher list
Q3TJZS	san-notebook	ZRJUXN	xx:xx:xx:xx:xx:xx	Wed Sep  8 23:47:40 2021	60	           -            	3	normal
```

## How it works

It uses nftables rules to filter inbound connections outside the mesh network.

## General overview of file hierarchy and function

```
files/
    /etc/config/pirania is the UCI config
    /etc/pirania/vouchers/ (default path) contains the database of vouchers
    /etc/init.d/pirania-uhttpd starts a uhttpd on port 59080 that replies any request with a redirect towards a preset URL

    /usr/lib/lua/voucher/ contains lua libraries used by /usr/bin/voucher
    /usr/bin/voucher is a CLI to manage the db (has functions list, list_active, show_authorized_macs, add, activate, deactivate and is_mac_authorized)
    /usr/bin/captive-portal sets up nftables rules to capture traffic

    /usr/libexec/rpcd/pirania ubus pirania API (this is used by the web frontend)
    /usr/share/rpcd/acl.d/pirania.json ACL for the ubus pirania API

    /etc/shared-state/publishers/shared-state-publish_vouchers inserts into shared-state the local voucher db
    /etc/shared-state/hooks/pirania/generate_vouchers bring updated or new vouchers from the shared-state database into the local voucher db

    /usr/lib/lua/read_for_access contains the library used by
    /usr/lib/lua/portal to manage access in read for access mode (aka without vouchers)

    /usr/bin/tranca-redes-scheduler evaluates the Tranca Redes schedule and toggles the active state
```

## ubus API

* `get_portal_config` -> returns portal configuration (activated, with_vouchers)
* `set_portal_config(activated, with_vouchers)` -> configures and starts/stops the portal
* `disable` -> disables the portal and stops captive-portal
* `show_url` -> returns the configured portal URL
* `change_url(url)` -> changes the portal URL
* `add_vouchers(name, qty, duration_m, activation_deadline, permanent, unrestricted)` -> creates vouchers
* `list_vouchers` -> lists all vouchers
* `rename(id, name)` -> renames a voucher
* `invalidate(id)` -> invalidates a voucher
* `get_portal_page_content` -> returns portal page content (title, text, logo, etc.)
* `set_portal_page_content(...)` -> sets portal page content

## Under the hood

### Traffic capture
`/usr/bin/captive-portal` sets up nftables rules to capture traffic.
It creates a set of rules and native nft sets:
* pirania-auth-macs: authorized macs go into this set. starts empty.
* pirania-allowlist-ipv4: with the members of the allowlist in the config file (10.0.0.0/8, 192.168.0.0/16, 172.16.0.0/12)
* pirania-allowlist-ipv6: same as ipv4 but for ipv6

Traffic capture is scoped to configured interfaces:
* `catch_interfaces`: L3 interfaces for direct nftables matching
* `catch_bridged_interfaces`: L2 bridged interfaces (e.g. Wi-Fi AP) for bridge-family marking

Rules:
* DNS packets, that are not from the allowed sets, are redirected to our own captive portal DNS at 59053
* HTTP packets, that are not from the allowed sets, are redirected to our own captive portal HTTP at 59080
* packets from the allowed sets are allowed
* the rest of the packets are rejected (drop and send an error to the client)

### HTTP flow


`/etc/init.d/pirania-uhttpd` starts a HTTP server (uhttpd) on port 59080 that replies any request with a redirect towards a preset URL.
 - In case that voucher usage is activated: `pirania.base_config.url_auth`.
 - Otherwise: `pirania.read_for_access.url_portal`
This is performed by the lua script `/www/pirania-redirect/redirect`. As both url are in the allowlist ip range (http://thisnode.info/portal/ by default) then the "normal" HTTP server listening in port 80 will answer after the redirect.

So the flow when using vouchers is:
* navigate to a non allowed ip: for example `http://orignal.org/baz/?foo=bar`
* get redirected with a 302 where you can put a voucher code to enter: `http://thisnode.info/cgi-bin/portal/auth.html?prev=http%3A%2F%2Foriginal.org%2Fbaz%2F%3Ffoo%3Dbar`
* submiting the form should perform a GET to `http://thisnode.info/cgi-bin/pirania/preactivate_voucher?voucher=secretcode&prev=http%3A%2F%2Foriginal.org%2Fbaz%2F%3Ffoo%3Dbar`
* The preactivate_voucher script does two different things depending on javascript support:
    * If nojs=true then the voucher is activated with the client MAC (taken from the ARP table with its IP) and the voucher code. If the activation succeeds it redirects to `url_authenticated`.
    * If nojs=false there is a check if the voucher code would be valid (there is an unused and valid voucher with that code). If the voucher would be valid then a redirect to the portal INFO page(`pirania.base_config.url_info`) is performed with the voucher code as param url. The portal info shows the updated information of the community and there is a time that you have to wait to be able to continue (This is done with JS). When the timer reaches 0 you can click in continue. This redirects now to `http://thisnode.info/cgi-bin/pirania/activate_voucher?voucher=secretcode`. The `activate_voucher` script does the voucher activation. then it redirects to `url_authenticated`. If the code fails it will redirect to `http://thisnode.info/cgi-bin/portal/fail.html` that is identical to auth.html but with an error message.

The flow without using vouchers (read for access mode) is:
* navigate to a non allowed ip: for example `http://orignal.org/baz/?foo=bar`
* get redirected with a 302 to: `http://thisnode.info/cgi-bin/portal/read_for_access.html?prev=http%3A%2F%2Foriginal.org%2Fbaz%2F%3Ffoo%3Dbar`
* Once there if the client has js support then a countdown of 15 seconds is shown and when it reaches 0 the user can click on continue, which sends a GET request to `http://thisnode.info/cgi-bin/pirania/authorize_mac?prev=http%3A%2F%2Foriginal.org%2Fbaz%2F%3Ffoo%3Dbar`
which will trigger a redirection to `prev` url.
* If there the client has no js support, then the button is enabled immediately, and after clicking in continue a redirection to `url_authenticated` is triggered.

### Tranca Redes

Tranca Redes is a second-layer access control mode that can restrict internet access during scheduled hours. When active:
* Authorized MACs can only reach destinations in configured category allowlists
* Unrestricted voucher holders bypass Tranca restrictions entirely
* Unauthorized MACs remain blocked as usual

Configuration is in `/etc/config/pirania` under the `tranca_redes` section:
* `enabled`: enable/disable Tranca Redes
* `start_time`/`end_time`: schedule in HH:MM format (supports overnight wrap)
* `days`: which days of the week Tranca is active
* `allowlist_category`: references category sections with IPv4 URL sources

The scheduler (`/usr/bin/tranca-redes-scheduler`) runs via cron every minute to evaluate the schedule.
