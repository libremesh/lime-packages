#!/bin/sh
((shared-state-publish_dnsmasq_leases $@; shared-state sync dnsmasq-leases; shared-state sync dnsmasq-hosts)&)
