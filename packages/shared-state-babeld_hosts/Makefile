# SPDX-License-Identifier: AGPL-3.0-only
#
# Copyright (C) 2019 Gioacchino Mazzurco <gio@altermundi.net>

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
