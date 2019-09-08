#
# Copyright (C) 2006-2014 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

LIME_BUILDDATE:=$(shell date +%Y%m%d_%H%M)

GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

PKG_NAME:=lime-hwd-ground-routing
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  TITLE:=Manage 802.1q VLANs for ground routing
  CATEGORY:=LiMe
  URL:=https://libremesh.org
  DEPENDS:=+lime-system +lua +libuci-lua
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	This package helps you to configure setups involving ground routing.
	With ground routing we mean setups having LibreMesh on a router
	which is connected via cable(s), eventually through a switch,
	to some wireless routers running the original firmware in WDS
	(transparent bridge) Ap/Sta mode. Configuring ground routing you
	will set up an interface with a different vlan or on a different
	switch port for each connected device in WDS mode.
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
