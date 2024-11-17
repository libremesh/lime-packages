# 
# Copyright (C) 2017 Pau Escrich
#
# This is free software, licensed under the GNU General Public License v3.
#

include ../../libremesh.mk

define Package/$(PKG_NAME)
  CATEGORY:=LibreMesh
  Section:=net
  TITLE:= Watchping hooks to manage AP SSID if network problems
  MAINTAINER:=Pau Escrich <p4u@dabax.et>
  URL:=http://libremesh.org
  DEPENDS:= +watchping +lime-system
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
  Watchping hooks to change AP ssid when the network is down (i.e LibreMesh-Error).
  So the WiFi roaming is broken and the clients are not using the AP anymore until fixed.
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
