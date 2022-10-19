include $(TOPDIR)/rules.mk

PKG_NAME:=ubus-tmate
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)
GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=SSH
  MAINTAINER:=Nicolas Pace <nicopace@altermundi.net>
  TITLE:=tmate.io ubus bindings
  DEPENDS:=+tmate +lime-system
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	It allows to create remote sessions over tmate through ubus.
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
