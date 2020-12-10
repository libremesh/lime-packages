#
# Copyright (C) 2019-2020 Gioacchino Mazzurco <gio@altermundi.net>
#
# This is free software, licensed under the GNU Affero General Public License v3.
#

include $(TOPDIR)/rules.mk

GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

PKG_NAME:=shared-state
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)

include $(INCLUDE_DIR)/package.mk

# Ugly hack to keep compatibility with Openwrt master and stable releases
ping6_legacy=0
ping6=iputils-ping
ping6_symlink=PING_LEGACY_SYMLINKS

# Detect OpenWrt 18.06
ifdef LINUX_4_9
ping6_legacy=1
endif

# Detect OpenWrt 18.06 and 19.07
ifdef LINUX_4_14
ping6_legacy=1
endif

ifeq ($(ping6_legacy),1)
ping6=iputils-ping6
ping6_symlink=PACKAGE_iputils-ping6
endif

define Package/$(PKG_NAME)
	TITLE:=Very minimal state sharing betwen nodes
	CATEGORY:=LiMe
	MAINTAINER:=Gioacchino Mazzurco <gio@altermundi.net>
	URL:=http://libremesh.org
	DEPENDS:=+libuci-lua +lime-system \
		+lua +luci-lib-jsonc +luci-lib-nixio +$(ping6) \
		+uclient-fetch
	PKGARCH:=all
endef

define Package/$(PKG_NAME)/config
	select $(ping6_symlink)
endef

define Package/$(PKG_NAME)/description
	LiMe style minimal unsecured CRDT to share light state between nodes
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
