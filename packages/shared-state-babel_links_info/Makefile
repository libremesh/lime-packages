# SPDX-License-Identifier: AGPL-3.0-only
#
# Copyright (c) 2023  Javier Jorge <jjorge@inti.gob.ar>
# Copyright (c) 2023  Instituto Nacional de Tecnología Industrial
# Copyright (C) 2023  Asociación Civil Altermundi <info@altermundi.net>

include ../../libremesh.mk

define Package/$(PKG_NAME)
	CATEGORY:=LibreMesh
	TITLE:=Babel links module for shared-state
	MAINTAINER:=Asociación Civil Altermundi <info@altermundi.net>
	DEPENDS:=+lua +luci-lib-jsonc +ubus-lime-utils \
		+libubus-lua +shared-state-ref_state_commons shared-state-async   
	PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	Synchronize Babel links information beween nodes.
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
