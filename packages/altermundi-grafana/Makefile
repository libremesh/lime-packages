#
# Copyright (C) 2006-2021 Gui Iribarren
#
# This is free software, licensed under the GNU General Public License v3.
#

include ../../libremesh.mk

define Package/$(PKG_NAME)
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=$(PKG_NAME) metapackage
  MAINTAINER:=Gui Iribarren <gui@altermundi.net>
  PKGARCH:=all
  DEPENDS:= \
            +prometheus-node-push-influx \
            +prometheus-node-exporter-lua \
            +prometheus-node-exporter-lua-openwrt \
            +prometheus-node-exporter-lua-wifi_stations \
            +prometheus-node-exporter-lua-wifi-stations-extra \
            +prometheus-node-exporter-lua-wifi-survey \
            +prometheus-node-exporter-lua-wifi-params \
            +prometheus-node-exporter-lua-location-latlon \

endef

define Package/$(PKG_NAME)/description
  This metapackage installs and configures a statistics collector system
  that gathers data on the node and pushes to https://grafana.altermundi.net
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
