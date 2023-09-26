#
# Copyright (C) 2023 Javier Jorge <jjorge@inti.gob.ar>
# Copyright (C) 2023  Asociación Civil Altermundi <info@altermundi.net>
# This is free software, licensed under the GNU Affero General Public License v3.
#

include ../../libremesh.mk

define Package/$(PKG_NAME)
	SECTION:=lime
	CATEGORY:=LibreMesh
	TITLE:=Node information module for shared-state
	MAINTAINER:= Javier <jjorge@inti.gob.ar>
	DEPENDS:=+lua +luci-lib-jsonc +ubus-lime-utils \
		+lime-system +ubus-lime-location shared-state   
	PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	Syncronize batman protocol links information beween nodes.
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
