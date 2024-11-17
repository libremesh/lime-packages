#
# Copyright (C) 2006-2014 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v3.
#

include ../../libremesh.mk

define Package/$(PKG_NAME)
  TITLE:=LiMe hardware detection usb radio support
  CATEGORY:=LibreMesh
  URL:=http://libremesh.org
  DEPENDS:=+lime-system +lua +libuci-lua +luci-lib-nixio
  PKGARCH:=all
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

