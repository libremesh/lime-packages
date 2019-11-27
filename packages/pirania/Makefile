#
## Copyright (C) 2019 Gui Iribarren <gui@altermundi.net>
#
## This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

PKG_NAME:=pirania
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/libremesh/pirania
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_VERSION:=c99c46b597018faff5806682e2f819002014635d
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION).tar.gz

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	TITLE:=$(PKG_NAME)
	MAINTAINER:=Marcos Gutierrez <gmarcos@altermundi.net>
	DEPENDS:= +ip6tables-mod-nat +ipset +uhttpd-mod-lua
	PKGARCH:=all
endef

define Package/$(PKG_NAME)-app
	SECTION:=net
	CATEGORY:=Network
	TITLE:=$(PKG_NAME)-app
	MAINTAINER:=Luandro <luandro@gmail.com>
	DEPENDS:= +pirania
	PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	Captive Portal for routers that want to share their Internet connection via vouchers.
endef

define Package/$(PKG_NAME)-app/description
	Simple web interface of Pirania. Allows you to manage vouchers and configure the initial screen.
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/
	$(CP) $(PKG_BUILD_DIR)/pirania/files/* $(1)/
endef

define Package/$(PKG_NAME)-app/install
	$(INSTALL_DIR) $(1)/
	$(CP) $(PKG_BUILD_DIR)/pirania-app/files/* $(1)/
endef


$(eval $(call BuildPackage,$(PKG_NAME)))
$(eval $(call BuildPackage,$(PKG_NAME)-app))
