#
# Copyright (C) 2019 Gui Iribarren <gui@altermundi.net>
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

PKG_NAME:=pirania
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/libremesh/pirania
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_VERSION:=ac5197e04ea9891fc73fe6c99a8d167d9024bdff
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION).tar.gz

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
 SECTION:=net
 CATEGORY:=Network
 TITLE:=$(PKG_NAME)
 MAINTAINER:=Nicolas Pace <nicopace@libre.ws>
 DEPENDS:= +ip6tables-mod-nat +ipset
 PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
 Captive Portal for routers that want to share their Internet connection via vouchers.
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/
	$(CP) $(PKG_BUILD_DIR)/files/* $(1)/
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/
	$(CP) $(PKG_BUILD_DIR)/luasrc/* $(1)/usr/lib/lua/luci/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
