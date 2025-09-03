# SPDX-License-Identifier: AGPL-3.0-only
#
# Copyright (C) 2019 Gioacchino Mazzurco <gio@altermundi.net>

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
