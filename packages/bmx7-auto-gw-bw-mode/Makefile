# 
# Copyright (C) 2018 Pau Escrich
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=bmx7-auto-gw-bw-mode
PKG_VERSION=0.1

include $(INCLUDE_DIR)/package.mk

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

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
