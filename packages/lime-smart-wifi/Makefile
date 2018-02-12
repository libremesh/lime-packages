include $(TOPDIR)/rules.mk

PKG_NAME:=lime-smart-wifi
PKG_VERSION:=0.2
PKG_RELEASE=2

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
 SECTION:=net
 CATEGORY:=LiMe
 TITLE:=Configure wifi mesh and ap hardware based
 MAINTAINER:=Paul Spooren <paul@spooren.de>
 URL:=http://libremesh.org
 DEPENDS:=+lime-system
endef

define Package/$(PKG_NAME)/description
 Automatically configure wifi mesh and ap based on existing radios
endef

define Build/Prepare
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(CP) ./src/lime-smart-wifi.lua $(1)/usr/bin/lime-smart-wifi
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
