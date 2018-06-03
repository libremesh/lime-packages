# 
# Copyright (C) 2017 Pau Escrich
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=smonit
PKG_VERSION=0.1

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  CATEGORY:=LiMe
  Section:=net
  TITLE:= Simple daemon monitoring tool
  MAINTAINER:=Pau Escrich <p4u@dabax.et>
  URL:=http://libremesh.org
  DEPENDS:=
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/config
  select CONFIG_BUSYBOX_CONFIG_CROND
  select CONFIG_BUSYBOX_CONFIG_CRONTAB
endef


define Package/$(PKG_NAME)/description
  Small modular daemon for monitoring system processes using hooks
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
