#
# Copyright (C) 2006-2014 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v3.
#

include ../../libremesh.mk

define Package/$(PKG_NAME)
  TITLE:=LiMe BGP proto support
  CATEGORY:=LibreMesh
  MAINTAINER:=Gioacchino Mazzurco <gio@diveni.re>
  URL:=http://libremesh.org
  DEPENDS:=+bird1-ipv4 +bird1-ipv6 +lime-system +lua +luci-lib-nixio
  PKGARCH:=all
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

