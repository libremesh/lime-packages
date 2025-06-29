#
# Copyright (C) 2019 Gioacchino Mazzurco <gio@altermundi.net>
#
# This is free software, licensed under the GNU Affero General Public License v3.
#

include ../../libremesh.mk

define Package/$(PKG_NAME)
	TITLE:=dnsmasq leases module for shared-state
	CATEGORY:=LibreMesh
	MAINTAINER:=Gioacchino Mazzurco <gio@altermundi.net>
	URL:=http://libremesh.org
	DEPENDS:=+libuci-lua +lua \
		+luci-lib-jsonc shared-state +shared-state-dnsmasq_hosts \
		+luci-lib-nixio
	PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	Syncronize dnsmasq leases beween nodes.
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
