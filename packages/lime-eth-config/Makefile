# SPDX-License-Identifier: AGPL-3.0-only
#
# Copyright (C) 2025 Javier Jorge <jjorge@inti.gob.ar>
# Copyright (c) 2025  Instituto Nacional de Tecnología Industrial
# Copyright (C) 2025  Asociación Civil Altermundi <info@altermundi.net>

include ../../libremesh.mk

define Package/$(PKG_NAME)
	TITLE:=Ethernet configuration for LibreMesh Lime-App
	CATEGORY:=LibreMesh
	MAINTAINER:=Asociación Civil Altermundi <info@altermundi.net>
	URL:=http://libremesh.org
	DEPENDS:=+libubus-lua +lime-system +lua +luci-lib-jsonc 
	PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	Ethernet port configuration for LibreMesh Lime-App.
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
