#
# Copyright (C) 2019 Gioacchino Mazzurco <gio@altermundi.net>
#
# This is free software, licensed under the GNU Affero General Public License v3.
#

include ../../libremesh.mk

define Package/$(PKG_NAME)
	TITLE:=dnsmasq hosts module for shared-state
	CATEGORY:=LibreMesh
	MAINTAINER:=Gioacchino Mazzurco <gio@altermundi.net>
	URL:=http://libremesh.org
	DEPENDS:=+lua +luci-lib-jsonc \
		shared-state
	PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	Syncronize dnsmasq hosts beween nodes.
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
