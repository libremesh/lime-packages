#
# Copyright (C) 2006-2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=altermap-agent
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)
GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=admin
  CATEGORY:=Administration
  TITLE:=Send system information to an AlterMap server
  MAINTAINER:=Gui Iribarren <gui@altermundi.net>
  DEPENDS:= +luci-lib-core +luci-lib-httpclient +luci-lib-json +luci-lib-nixio +libuci-lua
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
Small script that collects info (network settings, wifi stations, etc) from a router, and sends it to a map server.
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
