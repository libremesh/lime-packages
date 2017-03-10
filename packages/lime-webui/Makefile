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
LIME_CODENAME:=communitychaos

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)/Default
  SECTION:=net
  CATEGORY:=LiMe
  MAINTAINER:=p4u <pau@dabax.net>
  URL:=http://libremesh.org
endef

define Package/$(PKG_NAME)
  $(call Package/$(PKG_NAME)/Default)
  TITLE:=libremesh web user interface based on LUCI
  MENU:=1
  DEPENDS:= +luci-mod-admin-full +lime-system \
	+PACKAGE_lime-proto-bmx6:luci-app-bmx6 \
	+PACKAGE_lime-proto-batadv:luci-app-batman-adv \
	+luci-mod-status +uhttpd +libiwinfo-lua \
	+luci-theme-bootstrap +luci-i18n-base-en \
	+LIMEWEBUI_ES:luci-i18n-base-es +LIMEWEBUI_PT:luci-i18n-base-pt \
	+LIMEWEBUI_DE:luci-i18n-base-de
endef

define Package/$(PKG_NAME)/config
config LIMEWEBUI_ES
        bool "Spanish translation support"
        depends on PACKAGE_$(PKG_NAME)
        default n
        help
          Spanish translation support for $(PKG_NAME)
config LIMEWEBUI_PT
        bool "Portuguese translation support"
        depends on PACKAGE_$(PKG_NAME)
        default n
        help
          Portuguese translation support for $(PKG_NAME)
config LIMEWEBUI_DE
        bool "Deutsch translation support"
        depends on PACKAGE_$(PKG_NAME)
        default n
        help
          Deutsch translation support for $(PKG_NAME)
endef

define Package/$(PKG_NAME)/description
	Web interface for LibreMesh
endef

define Build/Prepare
	@rm -rf $(PKG_BUILD_DIR) || true
	mkdir -p $(PKG_BUILD_DIR)
	./build_i18n.sh
endef

define Build/Configure
endef

define Build/Compile
	@cp -r ./luasrc/. $(PKG_BUILD_DIR)/
	@find $(PKG_BUILD_DIR)/ -type f -name "*.lua" -exec sed -i '/^--!.*/d' {} \;
endef

ifneq ($(strip $(CONFIG_LIMEWEBUI_ES)),)
  TRANSLATIONS+=es 
endif

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi/lime
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/lime
	$(INSTALL_DIR) $(1)/www/luci-static/resources/lime
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	$(CP) $(PKG_BUILD_DIR)/model/* $(1)/usr/lib/lua/luci/model/cbi/lime/
	$(CP) $(PKG_BUILD_DIR)/controller/* $(1)/usr/lib/lua/luci/controller/
	$(CP) $(PKG_BUILD_DIR)/view/* $(1)/usr/lib/lua/luci/view/lime/
	$(CP) $(PKG_BUILD_DIR)/static/* $(1)/www/luci-static/resources/lime/
	$(foreach TR, $(TRANSLATIONS), $(CP) $(PKG_BUILD_DIR)/i18n/*.$(TR).lmo $(1)/usr/lib/lua/luci/i18n/ )
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
