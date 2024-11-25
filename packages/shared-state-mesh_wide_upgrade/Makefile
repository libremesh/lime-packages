#
# Copyright (c) 2023  Javier Jorge <jjorge@inti.gob.ar>
# Copyright (c) 2023  Instituto Nacional de Tecnología Industrial
# Copyright (C) 2023  Asociación Civil Altermundi <info@altermundi.net>
# This is free software, licensed under the GNU Affero General Public License v3.
#

include ../../libremesh.mk

define Package/$(PKG_NAME)
	CATEGORY:=LibreMesh
	TITLE:=Shared-state mesh upgrade information module
	MAINTAINER:=Asociación Civil Altermundi <info@altermundi.net>
	DEPENDS:=+lua +luci-lib-jsonc +ubus-lime-utils \
		+libubus-lua +random-numgen shared-state-async   
	PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	Synchronize node information to achieve mesh wide firmware upgrades
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
