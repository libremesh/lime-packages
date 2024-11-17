include ../../libremesh.mk

define Package/$(PKG_NAME)
    TITLE:=$(PKG_NAME)
    CATEGORY:=LibreMesh
    MAINTAINER:=Santiago Piccinini <spiccinini@altermundi.net>
    URL:=http://libremesh.org
    DEPENDS:= +lua +libubox-lua +libuci-lua +luci-lib-nixio +luci-lib-jsonc +libiwinfo-lua \
              +ubus-lime-utils +lime-system
    PKGARCH:=all
    DEPENDS:=+lime-system
endef

define Package/$(PKG_NAME)/description
	Scans surrounding LibreMesh networks and joins them.
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
