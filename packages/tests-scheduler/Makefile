# 
# Copyright (C) 2019 Ilario Gelmetti
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

PKG_NAME:=tests-scheduler
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  CATEGORY:=Utilities
  TITLE:=Tests scheduler at peak and night time
  MAINTAINER:=Ilario Gelmetti <ilario@sindominio.net>
  URL:=https://libremesh.org
  DEPENDS:=+at
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/config
endef

define Package/$(PKG_NAME)/description
 	Monitors the number of clients of the network for each hour,
	uses this information for scheduling tests at the peak time and/or at the night time.
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/bin/
	$(INSTALL_DIR) $(1)/etc/uci-defaults/
	$(INSTALL_DIR) $(1)/etc/config/
	$(INSTALL_BIN) ./files/bin/tests-scheduler-at.lua $(1)/bin/tests-scheduler-at
	$(INSTALL_BIN) ./files/bin/tests-scheduler-probe.lua $(1)/bin/tests-scheduler-probe
	$(INSTALL_BIN) ./files/etc/uci-defaults/* $(1)/etc/uci-defaults
	$(INSTALL_CONF) ./files/etc/config/tests-scheduler $(1)/etc/config/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
