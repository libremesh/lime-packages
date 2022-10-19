#
# Copyright (C) 2020 Santiago Piccinini <spiccinini@altermundi.net>
#
# This is free software, licensed under the GNU General Public License v3.
#

include ../../libremesh.mk

define Package/$(PKG_NAME)
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=$(PKG_NAME) provides semi automated firmware upgrades
  MAINTAINER:=Santiago Piccinini <spiccinini@altermundi.net>
  DEPENDS:=+lua +lime-system +luci-lib-jsonc
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	This $(PKG_NAME) provides semi automated firmware upgrades.
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
