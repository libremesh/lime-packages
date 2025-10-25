# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2006-2021 Gui Iribarren

include ../../libremesh.mk

define Package/$(PKG_NAME)
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Prometheus node exporter (wifi_survey collector)
  PKGARCH:=all
  MAINTAINER:=Gui Iribarren <gui@altermundi.net>
  DEPENDS:= +lua +iw +libubus-lua
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
