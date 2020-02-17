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
    /etc/pirania/db.csv (default path) contains the database of vouchers
    /etc/init.d/pirania-uhttpd starts a uhttpd on port 59080 that replies any request with a redirect towards a preset URL

    /usr/lib/lua/voucher/ contains lua libraries used by /usr/bin/voucher
    /usr/bin/voucher is a CLI to manage the db (has functions add_voucher, add_many_vouchers, auth_voucher, get_valid_macs, list_vouchers, remove_voucher and url)
    /usr/bin/captive-portal sets up iptables rules to capture traffic

    /usr/libexec/rpcd/pirania ubus pirania API (this is used by the web frontend)
    /usr/share/rpcd/acl.d/pirania.json ACL for the ubus pirania API
```