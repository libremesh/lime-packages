
include ../../libremesh.mk

define Package/$(PKG_NAME)
  SECTION:=ubus
  CATEGORY:=Ubus
  MAINTAINER:=Santiago Piccinini <spiccinini@altermundi.net>
  SUBMENU:=3. Applications
  TITLE:=Metrics ubus module
  DEPENDS:= +lua +libubox-lua +libubus-lua +luci-lib-jsonc +netperf +mtr +check-internet +lime-system +ubus-lime-utils
  PKGARCH:=all
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
