include ../../libremesh.mk

define Package/$(PKG_NAME)
  SECTION:=ubus
  CATEGORY:=Ubus
  MAINTAINER:=Marcos Gutierrez <gmarcos87@gmail.com>
  SUBMENU:=3. Applications
  TITLE:=Libremap ubus ground routing module
  DEPENDS:= +lua +libubox-lua +libubus-lua +libuci-lua +lime-system +luci-lib-jsonc +luci-compat
  PKGARCH:=all
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
