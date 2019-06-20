#!/bin/sh
((shared-state-publish_dnsmasq_leases $@) &>/dev/null &)
