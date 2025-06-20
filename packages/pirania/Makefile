include $(TOPDIR)/rules.mk

PKG_NAME:=pirania
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)
GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SUBMENU:=Captive Portals
  SECTION:=net
  CATEGORY:=Network
  MAINTAINER:=Asociación Civil AlterMundi <info@altermundi.net>
  TITLE:=Captive portal with vouchers.
  DEPENDS:=+nftables +uhttpd +uhttpd-mod-ubus +shared-state +shared-state-pirania \
	+uhttpd-mod-lua +lime-system +luci-lib-jsonc \
	+liblucihttp-lua +luci-lib-nixio +libubus-lua +libuci-lua
  PKGARCH:=all
endef
define Package/$(PKG_NAME)/description
	Captive Portal for routers that want to share their Internet connection via vouchers.
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
