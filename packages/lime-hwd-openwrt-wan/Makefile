#
# Copyright (C) 2006-2014 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v3.
#

include ../../libremesh.mk

define Package/$(PKG_NAME)
  TITLE:=Respect openwrt wan interface as default
  CATEGORY:=LibreMesh
  URL:=http://libremesh.org
  DEPENDS:=+lime-system +lua +libuci-lua +lime-proto-wan
  PKGARCH:=all
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
