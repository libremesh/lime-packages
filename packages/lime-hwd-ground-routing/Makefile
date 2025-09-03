# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2006-2014 OpenWrt.org

include ../../libremesh.mk

define Package/$(PKG_NAME)
  TITLE:=Manage 802.1q VLANs for ground routing
  CATEGORY:=LibreMesh
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

$(eval $(call BuildPackage,$(PKG_NAME)))
