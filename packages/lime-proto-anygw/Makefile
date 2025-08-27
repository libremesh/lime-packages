# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2006-2014 OpenWrt.org

include ../../libremesh.mk

define Package/$(PKG_NAME)
	TITLE:=LiMe anygw proto support
	CATEGORY:=LibreMesh
	MAINTAINER:=Gioacchino Mazzurco <gio@eigenlab.org>
	URL:=http://libremesh.org
	DEPENDS:=+dnsmasq-dhcpv6 +kmod-nft-bridge +libuci-lua \
		+lime-system +lua +kmod-macvlan \
		+shared-state +shared-state-dnsmasq_leases \
		+luci-lib-nixio +firewall4 +ip-bridge
  PKGARCH:=all
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

