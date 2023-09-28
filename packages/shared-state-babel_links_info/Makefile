#
# Copyright (c) 2023  Javier Jorge <jjorge@inti.gob.ar>
# Copyright (c) 2023  Instituto Nacional de Tecnología Industrial
# Copyright (C) 2023  Asociación Civil Altermundi <info@altermundi.net>
# This is free software, licensed under the GNU Affero General Public License v3.
#

include ../../libremesh.mk

define Package/$(PKG_NAME)
	SECTION:=lime
	CATEGORY:=LibreMesh
	TITLE:=Babel links information module for shared-state
	MAINTAINER:= Javier <jjorge@inti.gob.ar>
	DEPENDS:=+lua +luci-lib-jsonc +ubus-lime-utils \
		+libubus-lua shared-state   
	PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	Synchronize Babel links information beween nodes.
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
