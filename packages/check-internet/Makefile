# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2020 Santiago Piccinini <spiccinini@altermundi.net>

include ../../libremesh.mk

define Package/$(PKG_NAME)
	TITLE:=Check internet connection
	SECTION:=utils
	CATEGORY:=Utilities
	MAINTAINER:=Santiago Piccinini <spiccinini@altermundi.net>
	PKGARCH:=all
	DEPENDS:=+uclient-fetch +lime-system +luci-lib-jsonc +libubus-lua
endef

define Package/$(PKG_NAME)/description
	Simple script to verify that there is internet access.
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
