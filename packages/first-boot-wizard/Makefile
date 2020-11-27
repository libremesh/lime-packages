include $(TOPDIR)/rules.mk

PKG_NAME:=first-boot-wizard
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)
GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
    TITLE:=$(PKG_NAME)
    CATEGORY:=LiMe
    MAINTAINER:=Santiago Piccinini <spiccinini@altermundi.net>
    URL:=http://libremesh.org
    DEPENDS:= +lua +libubox-lua +libuci-lua +luci-lib-nixio +luci-lib-jsonc +libiwinfo-lua \
              +ubus-lime-utils +lime-system
    PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	Scans surrounding LibreMesh networks and joins them.
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
