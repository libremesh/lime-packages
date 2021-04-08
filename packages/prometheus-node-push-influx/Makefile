#
# Copyright (C) 2006-2021 Gui Iribarren
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=prometheus-node-push-influx
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)
GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=$(PKG_NAME) pushes influx line protocol over TCP
  MAINTAINER:=Gui Iribarren <gui@altermundi.net>
  PKGARCH:=all
  DEPENDS:= +lua +libuci-lua +luasocket
endef

define Package/$(PKG_NAME)/description
  Collects the same statistics as prometheus-node-exporter-lua,
  but instead of exposing them as a server, with prometheus syntax,
  pushes them using influx line protocol over TCP
  to a remote VictoriaMetrics server.
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
