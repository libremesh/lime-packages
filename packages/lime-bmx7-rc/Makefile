include $(TOPDIR)/rules.mk

PKG_NAME:=lime-bmx7-rc
PKG_VERSION:=0.0.2
PKG_RELEASE:=3

include $(INCLUDE_DIR)/package.mk

define Package/lime-bmx7-rc-client
  SECTION:=lime
  CATEGORY:=LiMe
  TITLE:=lime-bmx7-rc-client
  PKGARCH:=all
  DEPENDS:=bmx7 lime-system +bmx7-sms
endef

define Package/lime-bmx7-rc-client/description
	Checks for new config files and installs if sender is trusted
endef

define Build/Compile
endef

define Build/Configure
endef

define Package/lime-bmx7-rc-client/install
		$(INSTALL_DIR) $(1)/usr/bin
		$(CP) files/lime-bmx7-rc-client.sh $(1)/usr/bin/lime-bmx7-rc-client
		chmod +x $(1)/usr/bin/lime-bmx7-rc-client

		$(INSTALL_DIR) $(1)/etc/init.d
		$(CP) files/lime-bmx7-rc-client.procd $(1)/etc/init.d/lime-bmx7-rc-client
endef

define Package/lime-bmx7-rc-server
  SECTION:=lime
  CATEGORY:=LiMe
  TITLE:=lime-bmx7-rc-server
  PKGARCH:=all
  DEPENDS:=bmx7 lime-system +bmx7-sms
endef

define Package/lime-bmx7-rc-server/description
	Publishes installed lime-config to network and let other nodes use it
endef

define Build/Compile
endef

define Build/Configure
endef

define Package/lime-bmx7-rc-server/install
		$(INSTALL_DIR) $(1)/etc/uci-defaults
		$(CP) files/lime-bmx7-rc-server.defaults $(1)/etc/uci-defaults/lime-bmx7-rc-server
endef

$(eval $(call BuildPackage,lime-bmx7-rc-client))
$(eval $(call BuildPackage,lime-bmx7-rc-server))
