include $(TOPDIR)/libremesh.mk

PKG_NAME:=lime-hwd-watchcat

define Package/$(PKG_NAME)
  SECTION:=LibreMesh
  CATEGORY:=LibreMesh
  TITLE:=Watchcat HWD defaults 
  DEPENDS:=+lime-system +lua +libuci-lua +watchcat
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
Integrates OpenWrt’s watchcat into LibreMesh as a hardware-detection
module (HWD), reading ‘config hwd_watchcat’ from the LibreMesh UCI
and generating the real /etc/config/watchcat entries.
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

