#
# Copyright (C) 2019 Gioacchino Mazzurco <gio@altermundi.net>
#
# This is free software, licensed under the GNU Affero General Public License v3.
#

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
