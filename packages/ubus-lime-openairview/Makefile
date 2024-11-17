
include ../../libremesh.mk

define Package/$(PKG_NAME)
  SECTION:=ubus
  CATEGORY:=Ubus
  MAINTAINER:=Marcos Gutierrez <gmarcos87@gmail.com>
  SUBMENU:=3. Applications
  TITLE:=Openairview ubus module
  DEPENDS:= +lua +libubox-lua +libubus-lua +libiwinfo-lua +luci-lib-nixio +luci-lib-jsonc +lime-system
  PKGARCH:=all
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
