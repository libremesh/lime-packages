include ../../libremesh.mk

define Package/$(PKG_NAME)
	TITLE:=$(PKG_NAME) allows to use owut OpenWrt Upgrade Tool in LibreMesh
	CATEGORY:=LibreMesh
	URL:=http://libremesh.org
	DEPENDS:=+owut
  PKGARCH:=all
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

