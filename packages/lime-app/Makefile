#
# Copyright (C) Libremesh 2017
#
# This is free software, licensed under the GNU General Public License v3.

include $(TOPDIR)/rules.mk

PKG_NAME:=lime-app
PKG_VERSION:=v0.2.2
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_HASH:=b0c629f48d2a64ba60cc27a72fe318416afd170658718a0cf0ec0b59e3702005
PKG_SOURCE_URL:=https://github.com/libremesh/lime-app/releases/download/$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	CATEGORY:=LiMe
	TITLE:=LimeApp
	MAINTAINER:=Marcos Gutierrez <gmarcos@altermundi.net>
	URL:=http://github.com/libremesh/lime-app
	DEPENDS:=+uhttpd +uhttpd-mod-ubus \
		+ubus-lime-location +ubus-lime-metrics +ubus-lime-utils \
		+ubus-lime-openairview +ubus-lime-grondrouting
	PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	Light webApp for LibreMesh over uhttpd
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/www/app/
	$(CP) $(BUILD_DIR)/build/* $(1)/www/app/
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/lime-app.defaults $(1)/etc/uci-defaults/90_lime-app
	$(INSTALL_BIN) ./files/95-lime-app-rpc-acl $(1)/etc/uci-defaults/
	$(INSTALL_BIN) ./files/96-lime-app-index_page $(1)/etc/uci-defaults/
	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d || true
	$(INSTALL_DATA) ./files/lime_app_index.html $(1)/www/
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] ||	( /etc/init.d/rpcd restart && /etc/init.d/uhttpd restart ) || true
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
