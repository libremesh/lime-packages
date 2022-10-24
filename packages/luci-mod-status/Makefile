#
# Copyright (C) 2006-2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-mod-status
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)
GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=admin
  CATEGORY:=LuCI
  SUBMENU:=2. Modules
  TITLE:=LuCI status - some read-only info without login
  MAINTAINER:=Gui Iribarren <gui@altermundi.net>
  DEPENDS:= +uhttpd +luci-base +libiwinfo-lua +luci-lib-jquery-1-4 +luci-lib-jquery-flot-0-8 +luci-lib-json \
	    +luci-lib-nixio +luci-compat
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
Minimal and simple web app to view some status info:
 * a realtime plot of wifi neighbours signal (think "iw station dump")
 * batman-adv mesh nodes (if luci-app-batman-adv is installed)
 * bmx6 mesh nodes (if luci-app-bmx6 is installed)
 * ethernet switch ports status
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
