# Copyright (C) 2021 Santiago Piccinini <spiccinini@altermundi.net>
#
# This is free software, licensed under the GNU Affero General Public License v3.
#

include ../../libremesh.mk

define Package/$(PKG_NAME)
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Babel auto Internet gateway module.
  MAINTAINER:=Santiago Piccinini <spiccinini@altermundi.net>
  DEPENDS:=+libubus-lua +watchping +lime-proto-babeld
  PKGARCH:=all
endef


define Package/$(PKG_NAME)/description
	Watchping hooks to set babeld Internet automatic announcements.
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
