include ../../libremesh.mk

define Package/$(PKG_NAME)
  SECTION:=ubus
  CATEGORY:=Ubus
  MAINTAINER:=Santiago Piccinini <spiccinini@altermundi.net>
  SUBMENU:=3. Applications
  TITLE:=LIbremesh ubus utils module
  DEPENDS:= +lua +libubox-lua +libubus-lua +libuci +lime-system +libiwinfo-lua +cgi-io +rpcd-mod-file \
	    +luci-lib-jsonc

  PKGARCH:=all
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
