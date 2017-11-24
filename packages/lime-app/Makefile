# 
# Copyright (C) Libremesh 2017
#
# This is free software, licensed under the GNU General Public License v3.

include $(TOPDIR)/rules.mk

PKG_NAME:=lime-app
PKG_VERSION:=v0.1.0-alpha.1
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_HASH:=bd3dc0a092d63b55f053e8e37a10d1a20be32c074d2a0d7ac88d4277bd85fd3a
PKG_SOURCE_URL:=https://github.com/libremesh/lime-app/releases/download/$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	CATEGORY:=LiMe
	TITLE:=LimeApp
	MAINTAINER:=Marcos Gutierrez <gmarcos@altermundi.net>
	URL:=http://github.com/libremesh/lime-app
	DEPENDS:=+uhttpd +uhttpd-mod-ubus +ubus-lime-batman-adv +ubus-lime-bmx6 +ubus-lime-location +ubus-lime-metrics +ubus-lime-metrics +ubus-lime-utils
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
	@mkdir -p $(1)/usr/share/rpcd/acl.d || true
	$(INSTALL_BIN) ./files/unauthenticated.json $(1)/usr/share/rpcd/acl.d
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh

if ! uci show rpcd | grep -q lime-app; then
	uci add rpcd login
	uci set rpcd.@login[1].username='lime-app'
	uci set rpcd.@login[1].password='$1$$ta3C2yX4TvVObdaJyQ9Md1'
	uci add_list rpcd.@login[1].read='lime-app'
	uci add_list rpcd.@login[1].write='lime-app'
	uci commit rpcd
	/etc/init.d/rpcd restart && /etc/init.d/uhttpd restart
fi

exit 0
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
