#
# Copyright (C) 2006-2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=lime-webui
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)
LIME_CODENAME:=bigbang

include $(INCLUDE_DIR)/package.mk

define Package/lime-webui
  TITLE:=libre-mesh web user interface based on LUCI
  SECTION:=net
  CATEGORY:=LiMe
  URL:=http://libre-mesh.org
  DEPENDS:=+luci +luci-app-bmx6 +luci-app-batman-adv
endef

define Package/lime-webui/description
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

define Package/lime-webui/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi/lime
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/lime
	$(INSTALL_DIR) $(1)/www/luci-static/resources/lime
	$(CP) $(PKG_BUILD_DIR)/model/* $(1)/usr/lib/lua/luci/model/cbi/lime/
	$(CP) $(PKG_BUILD_DIR)/controller/* $(1)/usr/lib/lua/luci/controller/
	$(CP) $(PKG_BUILD_DIR)/view/* $(1)/usr/lib/lua/luci/view/lime/
	$(CP) $(PKG_BUILD_DIR)/static/* $(1)/www/luci-static/resources/lime/
endef

$(eval $(call BuildPackage,lime-webui))
