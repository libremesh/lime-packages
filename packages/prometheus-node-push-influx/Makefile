#
# Copyright (C) 2006-2021 Gui Iribarren
#
# This is free software, licensed under the GNU General Public License v3.
#

include ../../libremesh.mk

define Package/$(PKG_NAME)
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=$(PKG_NAME) pushes influx line protocol over TCP
  MAINTAINER:=Gui Iribarren <gui@altermundi.net>
  PKGARCH:=all
  DEPENDS:= +lua +libuci-lua +luasocket +libubus-lua
endef

define Package/$(PKG_NAME)/description
  Collects the same statistics as prometheus-node-exporter-lua,
  but instead of exposing them as a server, with prometheus syntax,
  pushes them using influx line protocol over TCP
  to a remote VictoriaMetrics server.
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
