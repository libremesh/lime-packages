#
# Copyright (C) 2006-2014 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v3.
#

include ../../libremesh.mk

define Package/$(PKG_NAME)
	TITLE:=LiMe anygw proto support
	CATEGORY:=LibreMesh
	MAINTAINER:=Gioacchino Mazzurco <gio@eigenlab.org>
	URL:=http://libremesh.org
	DEPENDS:=+dnsmasq-dhcpv6 +kmod-nft-bridge +libuci-lua \
		+lime-system +lua +kmod-macvlan \
		+shared-state +shared-state-dnsmasq_leases \
		+luci-lib-nixio +firewall4
  PKGARCH:=all
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

