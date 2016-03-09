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

LIME_CODENAME:=bigbang

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  TITLE:=libre-mesh web user interface based on LUCI
  SECTION:=net
  CATEGORY:=LiMe
  MAINTAINER:=p4u <pau@dabax.net>
  URL:=http://libre-mesh.org
  DEPENDS:= +luci-mod-admin-full \
	+PACKAGE_lime-proto-bmx6:luci-app-bmx6 \
	+PACKAGE_lime-proto-batadv:luci-app-batman-adv \
	+luci-mod-status \
	+uhttpd +libiwinfo-lua \
	+luci-theme-bootstrap +luci-i18n-english
endef

define Package/$(PKG_NAME)/description
	Web interface for Libre-Mesh
endef

define Build/Prepare
	@rm -rf $(PKG_BUILD_DIR) || true
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Configure
endef

define Build/Compile
	@cp -r ./src/. $(PKG_BUILD_DIR)/
	@find $(PKG_BUILD_DIR)/ -type f -name "*.lua" -exec sed -i '/^--!.*/d' {} \;
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi/lime
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/lime
	$(INSTALL_DIR) $(1)/www/luci-static/resources/lime
	$(CP) $(PKG_BUILD_DIR)/model/* $(1)/usr/lib/lua/luci/model/cbi/lime/
	$(CP) $(PKG_BUILD_DIR)/controller/* $(1)/usr/lib/lua/luci/controller/
	$(CP) $(PKG_BUILD_DIR)/view/* $(1)/usr/lib/lua/luci/view/lime/
	$(CP) $(PKG_BUILD_DIR)/static/* $(1)/www/luci-static/resources/lime/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
