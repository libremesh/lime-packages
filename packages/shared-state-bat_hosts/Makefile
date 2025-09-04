# SPDX-License-Identifier: AGPL-3.0-only
#
# Copyright (C) 2019-2024 Gioacchino Mazzurco <gio@altermundi.net>

include ../../libremesh.mk

define Package/$(PKG_NAME)
	TITLE:=bat-hosts module for shared-state
	CATEGORY:=LibreMesh
	MAINTAINER:=Asociación Civil Altermundi <info@altermundi.net>
	URL:=http://libremesh.org
	DEPENDS:=+libubus-lua +lime-system +lua +luci-lib-jsonc +luci-lib-nixio \
	         +shared-state-async
	PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	Syncronize bat-hosts beween nodes, provides also mac2bat and bat2mac.
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
