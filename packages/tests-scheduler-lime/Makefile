# 
# Copyright (C) 2019 Ilario Gelmetti
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

PKG_NAME:=tests-scheduler-lime
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  CATEGORY:=LiMe
  TITLE:=LibreMesh tests for tests-scheduler
  MAINTAINER:=Ilario Gelmetti <ilario@sindominio.net>
  URL:=https://libremesh.org
  DEPENDS:=+logrotate +lime-report +bandwidth-test
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/config
endef

define Package/$(PKG_NAME)/description
	Schedules a few tests which gather useful information for debugging
	a LibreMesh network.
	The scheduling is done using the tests-scheduler package and can be run
	at the network usage peak time or at the night time.
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/logrotate.d/
	$(INSTALL_DIR) $(1)/etc/tests-scheduler/nightHooks.d/
	$(INSTALL_DIR) $(1)/etc/tests-scheduler/peakHooks.d/
	$(INSTALL_BIN) ./files/etc/logrotate.d/* $(1)/etc/logrotate.d
	$(INSTALL_BIN) ./files/etc/tests-scheduler/nightHooks.d/* $(1)/etc/tests-scheduler/nightHooks.d/
	$(INSTALL_BIN) ./files/etc/tests-scheduler/peakHooks.d/* $(1)/etc/tests-scheduler/peakHooks.d/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
