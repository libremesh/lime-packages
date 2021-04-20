#
# Copyright (C) 2006-2021 Gui Iribarren
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=altermundi-grafana
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)
GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

include $(INCLUDE_DIR)/package.mk

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
            +prometheus-node-exporter-lua-wifi_stations_extra \

endef

define Package/$(PKG_NAME)/description
  This metapackage installs and configures a statistics collector system
  that gathers data on the node and pushes to https://grafana.altermundi.net
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
