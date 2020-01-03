include $(TOPDIR)/rules.mk

PKG_NAME:=pirania-app
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)
GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=ubus
  CATEGORY:=Ubus
  MAINTAINER:=Luandro <luandro@gmail.com>
  SUBMENU:=3. Applications
  TITLE:=Libremesh first boot wizard ubus module
  DEPENDS:= +ip6tables-mod-nat +ipset +uhttpd-mod-lua
  PKGARCH:=all
endef

define Package/$(PKG_NAME)-app/description
	Simple web interface of Pirania. Allows you to manage vouchers and configure the initial screen.
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
