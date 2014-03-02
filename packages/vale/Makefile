#
# Copyright (C) 2006-2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=vale
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)
GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
 SECTION:=net
 CATEGORY:=Network
 TITLE:=$(PKG_NAME)
 MAINTAINER:=Gui Iribarren <gui@altermundi.net>
endef

define Package/$(PKG_NAME)/description
 Small utility for managing one-time-vouchers with nodogsplash.
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin $(1)/etc/nodogsplash/vale
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/vale $(1)/usr/bin/
	$(INSTALL_BIN) ./files/usr/bin/vale-wrapper $(1)/usr/bin/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/config $(1)/etc/nodogsplash/vale/config
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/vale_used $(1)/etc/nodogsplash/vale/vale_used
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/clients $(1)/etc/nodogsplash/vale/clients
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
