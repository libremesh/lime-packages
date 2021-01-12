include ../../libremesh.mk

define Package/$(PKG_NAME)
  SECTION:=lime
  CATEGORY:=LibreMesh
  TITLE:=Configure wifi mesh and ap hardware based
  DEPENDS:=+lime-system
  MAINTAINER:=Paul Spooren <paul@spooren.de>
  VERSION:=$(if $(PKG_VERSION),$(PKG_VERSION),$(PKG_SRC_VERSION))
  PKGARCH:=all
  URL:=https://github.com/libremesh/lime-packages/
endef


define Package/$(PKG_NAME)/description
	Automatically configure wifi mesh and ap based on existing radios
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
