include $(TOPDIR)/rules.mk

PKG_NAME:=cotonete
PKG_VERSION:=0.0.1

PKG_MAINTAINER:=Nicolas Pace <nico@libre.ws>
PKG_LICENSE:=LGPL-2.1+

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
    TITLE:=$(PKG_NAME)
    CATEGORY:=Network
    MAINTAINER:=Nicolas Pace <nico@libre.ws>
    URL:=http://www.libremesh.org/
    DEPENDS:=
endef

define Package/$(PKG_NAME)/description
    Cotonete monitors mesh devices looking for the dead phys ath9k bug, and logs when it happens.
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/
	$(CP) ./files/* $(1)/
	@chmod a+x $(1)/etc/init.d/cotonete
	@chmod a+x $(1)/usr/sbin/cotonete.sh
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
