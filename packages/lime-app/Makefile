#
# Copyright (C) Libremesh 2017
#
# This is free software, licensed under the GNU General Public License v3.

include $(TOPDIR)/rules.mk

PKG_NAME:=lime-app
PKG_VERSION:=0.2.26
PKG_RELEASE:=2

PKG_SOURCE:=$(PKG_NAME)-v$(PKG_VERSION).tar.gz
PKG_HASH:=afb74137af470f1a07d75870d569776e0eef05cce30682f58fed601e4a457d62
PKG_SOURCE_URL:=https://github.com/libremesh/lime-app/releases/download/v$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	CATEGORY:=LibreMesh
	TITLE:=LimeApp
	MAINTAINER:=German Ferrero <germanferrero@altermundi.net>
	URL:=http://github.com/libremesh/lime-app
	DEPENDS:=+rpcd +uhttpd +uhttpd-mod-ubus +uhttpd-mod-lua \
		+ubus-lime-location +ubus-lime-metrics +ubus-lime-utils \
		+rpcd-mod-iwinfo +ubus-lime-groundrouting
	PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	Light webApp for LibreMesh over uhttpd
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/
	$(CP) ./files/* $(1)/
	$(INSTALL_DIR) $(1)/www/app/
	$(CP) $(BUILD_DIR)/build/* $(1)/www/app/
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] ||	( /etc/init.d/rpcd restart && /etc/init.d/uhttpd restart ) || true
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
