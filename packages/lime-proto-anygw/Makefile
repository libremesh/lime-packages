#
# Copyright (C) 2006-2014 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

LIME_BUILDDATE:=$(shell date +%Y%m%d_%H%M)

GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

PKG_NAME:=lime-proto-anygw
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	TITLE:=LiMe anygw proto support
	CATEGORY:=LibreMesh
	MAINTAINER:=Gioacchino Mazzurco <gio@eigenlab.org>
	URL:=http://libremesh.org
	DEPENDS:=+dnsmasq-dhcpv6 +kmod-nft-bridge +libuci-lua \
		+lime-system +lua +kmod-macvlan \
		+shared-state +shared-state-dnsmasq_leases \
		+luci-lib-nixio +firewall4
  PKGARCH:=all
endef

define Build/Compile
	@rm -rf ./build || true
	@mkdir ./build
	$(CP) ./files ./build
	$(FIND) ./build -name '*.sh' -exec sed -i '/^\s*#\[Doc\]/d' {} +
	$(FIND) ./build -name '*.lua' -exec sed -i '/^\s*--!.*/d' {} +
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/
	$(CP) ./build/files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

