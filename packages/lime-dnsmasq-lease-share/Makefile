#
# Copyright (C) 2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v3.
#


include $(TOPDIR)/rules.mk

PKG_NAME:=lime-dnsmasq-lease-share
PKG_VERSION:=0.1
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)/

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
 MAINTAINER:=Gioacchino Mazzurco <gio@eigenlab.org>
 SECTION:=net
 CATEGORY:=LiMe
 TITLE:=dnsmasq lease sharing accross batman-adv mesh
 URL:=http://libre-mesh.org
 DEPENDS:=+alfred +lua +libuci-lua
endef

define Package/$(PKG_NAME)/description
 Share dnsmasq lease file accross all batman-adv nodes of a mesh with enabled alfred
endef

define Build/Prepare
	@rm -rf $(PKG_BUILD_DIR) || true
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Configure
endef

define Build/Compile
	@cp -r ./src/. $(PKG_BUILD_DIR)/
	@sed -i '/^--!.*/d' $(PKG_BUILD_DIR)/*.lua
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	@cp $(PKG_BUILD_DIR)/$(PKG_NAME).lua $(1)/usr/bin/$(PKG_NAME)
	@chmod +x $(1)/usr/bin/$(PKG_NAME)
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
