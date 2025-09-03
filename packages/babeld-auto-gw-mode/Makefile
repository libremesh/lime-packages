# SPDX-License-Identifier: AGPL-3.0-only
#
# Copyright (C) 2021 Santiago Piccinini <spiccinini@altermundi.net>

include ../../libremesh.mk

define Package/$(PKG_NAME)
  SECTION:=lime
  CATEGORY:=LibreMesh
  TITLE:=Babel auto Internet gateway module.
  MAINTAINER:=Santiago Piccinini <spiccinini@altermundi.net>
  DEPENDS:=+libubus-lua +watchping +lime-proto-babeld +lime-system
  PKGARCH:=all
endef


define Package/$(PKG_NAME)/description
	Watchping hooks to set babeld Internet automatic announcements.
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
