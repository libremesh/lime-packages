#
# Copyright (C) 2006-2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=lime-webui
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)
GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)
LIME_CODENAME:=bigbang

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  TITLE:=libre-mesh web user interface based on LUCI
  SECTION:=net
  CATEGORY:=LiMe
  MAINTAINER:=p4u <pau@dabax.net>
  URL:=http://libre-mesh.org
  DEPENDS:=+luci +luci-app-bmx6 +luci-app-batman-adv
endef

define Package/$(PKG_NAME)/description
	Web interface for Libre-Mesh
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi/lime
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/lime
	$(INSTALL_DIR) $(1)/www/luci-static/resources/lime
	$(CP) ./src/model/* $(1)/usr/lib/lua/luci/model/cbi/lime/
	$(CP) ./src/controller/* $(1)/usr/lib/lua/luci/controller/
	$(CP) ./src/view/* $(1)/usr/lib/lua/luci/view/lime/
	$(CP) ./src/static/* $(1)/www/luci-static/resources/lime/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
