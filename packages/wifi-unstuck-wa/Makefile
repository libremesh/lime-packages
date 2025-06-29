#
# Copyright (C) 2019 Santiago Piccinini <spiccinini@altermundi.net>
#
# This is free software, licensed under the GNU General Public License v3.
#

include ../../libremesh.mk

define Package/$(PKG_NAME)
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=$(PKG_NAME) provides workarounds for radio bugs
  MAINTAINER:=Santiago Piccinini <spiccinini@altermundi.net>
  DEPENDS:=+lua +lime-system +luci-lib-nixio
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	This $(PKG_NAME) is a collection of workarounds to radio and/or
	radio driver bugs.
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
