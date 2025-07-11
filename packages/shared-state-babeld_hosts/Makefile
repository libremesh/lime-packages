#
# Copyright (C) 2019 Gioacchino Mazzurco <gio@altermundi.net>
#
# This is free software, licensed under the GNU Affero General Public License v3.
#

include ../../libremesh.mk

define Package/$(PKG_NAME)
	TITLE:=babeld-hosts module for shared-state
	CATEGORY:=LibreMesh
	MAINTAINER:=Gioacchino Mazzurco <gio@altermundi.net>
	URL:=http://libremesh.org
	DEPENDS:=+hotplug-initd-services \
		+lua +luci-lib-jsonc shared-state
	PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	Maintain a shared babel_id-hostname translation table, provides also
	bab2host and host2bab commands.
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
