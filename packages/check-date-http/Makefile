# SPDX-License-Identifier: AGPL-3.0-only
#
# Copyright (C) 2019 Gioacchino Mazzurco <gio@altermundi.net>

include ../../libremesh.mk

define Package/$(PKG_NAME)
	TITLE:=Keep local date under NTP too far away skew
	CATEGORY:=LibreMesh
	MAINTAINER:=Gioacchino Mazzurco <gio@altermundi.net>
	URL:=http://libremesh.org
	DEPENDS:=+libuci-lua +lua 
	PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	Check local time against a list of HTTP(s) services, if the time skew is
	more then 15 minutes, restart sysntpd to force time syncronization, or
	reset trought date command depending on configuration.
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
