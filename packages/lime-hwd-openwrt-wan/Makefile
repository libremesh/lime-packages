# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2006-2014 OpenWrt.org

include ../../libremesh.mk

define Package/$(PKG_NAME)
  TITLE:=Respect openwrt wan interface as default
  CATEGORY:=LibreMesh
  URL:=http://libremesh.org
  DEPENDS:=+lime-system +lua +libuci-lua +lime-proto-wan
  PKGARCH:=all
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
