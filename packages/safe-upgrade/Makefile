#
# Copyright (C) 2019 Santiago Piccinini <spiccinini@altermundi.net>
#
# This is free software, licensed under the GNU General Public License v3.
#

include ../../libremesh.mk

define Package/$(PKG_NAME)
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=$(PKG_NAME) provides safe firmware upgrades using two partitions.
  MAINTAINER:=Santiago Piccinini <spiccinini@altermundi.net>
  DEPENDS:=+lua-argparse +luci-lib-jsonc +lime-system
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	$(PKG_NAME) provides safe firmware upgrades using two partitions and a
	confirmation step. See $(PKG_NAME)/Readme.md for more details.
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
