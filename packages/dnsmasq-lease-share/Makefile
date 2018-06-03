#
# Copyright (C) 2006-2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=dnsmasq-lease-share
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)
GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
 SECTION:=net
 CATEGORY:=LiMe
 TITLE:=dnsmasq lease sharing across mesh
 MAINTAINER:=Gioacchino Mazzurco <gio@eigenlab.org>
 URL:=http://libremesh.org
 DEPENDS:=+alfred +lua +libuci-lua
 PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
 Share dnsmasq DHCP lease file across nodes of the same mesh cloud
endef

define Build/Prepare
	@cp -r ./src $(PKG_BUILD_DIR)/
endef

define Build/Compile
	@sed -i '/^--!.*/d' $(PKG_BUILD_DIR)/src/*.lua
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/alfred
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/dnsmasq-lease-share.lua $(1)/etc/alfred/dnsmasq-lease-share.lua
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/dnsmasq-lease-share.sh $(1)/usr/bin/dnsmasq-lease-share.sh
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
