include $(TOPDIR)/rules.mk

PKG_NAME:=lime-mesh-upgrade
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)
GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  CATEGORY:=LibreMesh
  MAINTAINER:=selankon <selankon@selankon.xyz>
  SUBMENU:=3. Applications
  TITLE:=LibreMesh mesh wide firmware upgrade
  DEPENDS:= +lua +libubus-lua +sysupgrade +wget +lime.utils
  PKGARCH:=all
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
