include $(TOPDIR)/rules.mk

PKG_NAME:=services
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)
GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SUBMENU:=Services
  SECTION:=net
  CATEGORY:=Network
  MAINTAINER:=Luandro <luandro@digital-democracy.org>
  TITLE:=Service discovery
  DEPENDS:=
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	Services discovery for Community Networks.
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
