# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2006-2016 OpenWrt.org

include ../../libremesh.mk

define Package/$(PKG_NAME)
	TITLE:=LiMe OLSR2 proto support (IPv4/v6)
	CATEGORY:=LibreMesh
	MAINTAINER:=Gabriel <gabriel@autistici.org>
	URL:=http://libremesh.org
	DEPENDS:=+lua +libuci-lua +lime-system +oonf-olsrd2 +luci-lib-ip \
		 +luci-lib-nixio
	PKGARCH:=all
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
