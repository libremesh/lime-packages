# SPDX-License-Identifier: AGPL-3.0-only
#
# Copyright (C) 2019 Marcos Gutierrez <gmarcos@altermundi.net>

include ../../libremesh.mk

define Package/$(PKG_NAME)
	TITLE:=Persists shared-state in usb devices
	CATEGORY:=LibreMesh
	MAINTAINER:=Marcos Gutierrez <gmacos@altermundi.net>
	URL:=http://libremesh.org
	DEPENDS:=+block-mount +kmod-usb-storage +kmod-fs-vfat\
		shared-state +luci-lib-nixio
	PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	Detects block-mount storage devices and configures shared-state so that status persists on those devices.
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
