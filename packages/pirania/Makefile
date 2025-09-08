include ../../libremesh.mk

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

$(eval $(call BuildPackage,$(PKG_NAME)))
