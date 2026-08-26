# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2006-2014 OpenWrt.org

include ../../libremesh.mk

define Package/$(PKG_NAME)
	TITLE:=libremesh debug utils
	CATEGORY:=LibreMesh
	MAINTAINER:=Gioacchino Mazzurco <gio@eigenlab.org>
	URL:=http://libremesh.org
	DEPENDS:=+bandwidth-test \
		+busybox +ethtool +iwinfo +iw +mtr +ip \
		+iputils-ping \
		+sprunge +safe-reboot +netperf +pv +tcpdump-mini +bwm-ng \
		+lime-report +iperf3 +jq
	PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	Debug utilities for LibreMesh nodes
endef

define Package/$(PKG_NAME)/config
	select BUSYBOX_CUSTOM
	select BUSYBOX_CONFIG_NC
	select BUSYBOX_CONFIG_NC_SERVER
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
