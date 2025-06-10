include ../../libremesh.mk

define Package/$(PKG_NAME)
  SECTION:=lime
  CATEGORY:=LibreMesh
  TITLE:=Watchcat LibreMesh configurer 
  DEPENDS:=+lime-system +lua +watchcat
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
Integrates OpenWrt’s watchcat into LibreMesh as a hardware-detection
module (HWD), reading ‘config hwd_watchcat’ from the LibreMesh UCI
and generating the real /etc/config/watchcat entries.
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
