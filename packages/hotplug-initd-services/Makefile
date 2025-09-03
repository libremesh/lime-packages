# SPDX-License-Identifier: AGPL-3.0-only
#
# Copyright (C) 2019 Gioacchino Mazzurco <gio@altermundi.net>

include ../../libremesh.mk

define Package/$(PKG_NAME)
	TITLE:=Hotplug events of init.d services
	CATEGORY:=LibreMesh
	MAINTAINER:=Gioacchino Mazzurco <gio@altermundi.net>
	URL:=http://libremesh.org
	DEPENDS:=+libubox-lua +libubus-lua \
		+lua +luci-lib-nixio
	PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	Provide trigger hotplug events when init.d services are started and
	stopped. Put your hooks into /etc/hotplug.d/initd/.
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
