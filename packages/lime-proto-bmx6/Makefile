#
# Copyright (C) 2006-2014 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

LIME_BUILDDATE:=$(shell date +%Y%m%d_%H%M)
LIME_CODENAME:=DaybootRely

GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

PKG_NAME:=lime-proto-bmx6
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  TITLE:=LiMe Bmx6 proto support
  CATEGORY:=LiMe
  MAINTAINER:=Gioacchino Mazzurco <gio@eigenlab.org>
  URL:=http://libremesh.org
  DEPENDS:=+bmx6 +bmx6-json +bmx6-sms +bmx6-table +bmx6-uci-config +!PACKAGE_firewall:iptables \
  +lime-system +lua +libuci-lua +kmod-ebtables-ipv6
endef

define Build/Compile
	@rm -rf ./build || true
	@cp -r ./src ./build
	@sed -i '/^--!.*/d' build/*.lua
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/lime/proto
	$(CP) ./build/bmx6.lua $(1)/usr/lib/lua/lime/proto/
	$(INSTALL_DIR) $(1)/usr/bin/
	$(INSTALL_DIR) $(1)/etc/uci-defaults/
	$(INSTALL_BIN) ./build/bmx6hosts $(1)/usr/bin/
	$(INSTALL_BIN) ./build/85-add-bmx6-addresses-to-hosts $(1)/etc/uci-defaults/
	$(INSTALL_BIN) ./build/bmx6hosts_dnsmasq_update $(1)/usr/bin/bmx6hosts_dnsmasq_update
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

