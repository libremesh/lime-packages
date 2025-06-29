#
# Copyright (C) 2006-2021 Gui Iribarren
#
# This is free software, licensed under the GNU General Public License v3.
#

include ../../libremesh.mk

define Package/$(PKG_NAME)
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Prometheus node exporter (location_latlon collector)
  PKGARCH:=all
  MAINTAINER:=Gui Iribarren <gui@altermundi.net>
  DEPENDS:= +lua +libuci-lua +iw +libubus-lua
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
