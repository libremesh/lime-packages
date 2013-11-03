#
# Copyright (C) 2006-2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
# Author: Gioacchino Mazzurco <gio@eigenlab.org>

include $(TOPDIR)/rules.mk

PKG_NAME:=lime-dnsmasq-lease-share
PKG_VERSION:=0.1
PKG_RELEASE:=3

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
 SECTION:=net
 CATEGORY:=Network
 TITLE:=dnsmasq lease sharing accross batman-adv mesh
 DEPENDS:=+alfred +lua +libuci-lua
endef

define Package/$(PKG_NAME)/description
 Share dnsmasq lease file accross all batman-adv nodes of a mesh with enabled alfred
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Configure
endef

define Build/Compile
	@rm -rf ./build || true
	@cp -r ./src ./build
	@sed -i '/^--!.*/d' ./build/*.lua
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(CP) ./build/$(PKG_NAME).lua $(1)/usr/bin/$(PKG_NAME)
	@chmod +x $(1)/usr/bin/$(PKG_NAME)
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
