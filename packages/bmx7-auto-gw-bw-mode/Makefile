# 
# Copyright (C) 2018 Pau Escrich
#
# This is free software, licensed under the GNU General Public License v3.
#

include ../../libremesh.mk

PKG_VERSION:=0.0.1
PKG_RELEASE:=1

define Package/$(PKG_NAME)
  CATEGORY:=LibreMesh
  Section:=net
  TITLE:= bmx7 auto Internet gateway bandwidth module
  MAINTAINER:=Pau Escrich <p4u@dabax.et>
  URL:=http://libremesh.org
  DEPENDS:=+bmx7-auto-gw-mode +pv
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/config
  select CONFIG_BUSYBOX_CONFIG_CROND
  select CONFIG_BUSYBOX_CONFIG_CRONTAB
endef

define Package/$(PKG_NAME)/description
  	Watchping hooks to set bmx7 Internet bandwidth announcement
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
