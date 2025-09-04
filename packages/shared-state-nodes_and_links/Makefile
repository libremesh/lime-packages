# SPDX-License-Identifier: AGPL-3.0-only
#
# Copyright (C) 2019 Gioacchino Mazzurco <gio@altermundi.net>

include ../../libremesh.mk

define Package/$(PKG_NAME)
	TITLE:=nodes_and_links module for shared-state
	CATEGORY:=LibreMesh
	MAINTAINER:=Nicolas Pace <nico@libre.ws>
	URL:=http://libremesh.org
	DEPENDS:=+lua +luci-lib-jsonc \
		shared-state +ubus-lime-location
	PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	Syncronize nodes_and_links beween nodes.
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
