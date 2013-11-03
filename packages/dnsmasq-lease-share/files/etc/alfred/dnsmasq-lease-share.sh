#!/bin/sh

# http://lists.thekelleys.org.uk/pipermail/dnsmasq-discuss/2013q4/007750.html
# dnsmasq doesn't support reinitialising internal lease database without restart
[ ! -z "$(pidof dnsmasq)" ] && /etc/init.d/dnsmasq restart
