include ../../libremesh.mk

define Package/$(PKG_NAME)
	TITLE:=owut - an OpenWrt Upgrade Tool - for LibreMesh
	CATEGORY:=LibreMesh
	MAINTAINER:=Samuele Longhi <agave@dracaena.it>
	DEPENDS:=+owut
	PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	The OpenWrt Upgrade Tool (owut) with uci-defaults scripts to also use the LibreMesh package repositories.
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
