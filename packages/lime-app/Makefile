#
# Copyright (C) Libremesh 2017
#
# This is free software, licensed under the GNU General Public License v3.

include $(TOPDIR)/rules.mk

PKG_NAME:=lime-app
PKG_VERSION:=v0.2.23
PKG_RELEASE:=2

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_HASH:=6f2ae40404c229e75a8aff10e26cff32f43163bde7a468d69559baede3d570dd
PKG_SOURCE_URL:=https://repo.libremesh.org/limeapp/$(PKG_SOURCE)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	CATEGORY:=LibreMesh
	TITLE:=LimeApp
	MAINTAINER:=German Ferrero <germanferrero@altermundi.net>
	URL:=http://github.com/libremesh/lime-app
	DEPENDS:=+rpcd +uhttpd +uhttpd-mod-ubus +uhttpd-mod-lua \
		+ubus-lime-location +ubus-lime-metrics +ubus-lime-utils \
		+rpcd-mod-iwinfo +ubus-lime-grondrouting
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
	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d || true
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] ||	( /etc/init.d/rpcd restart && /etc/init.d/uhttpd restart ) || true
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
