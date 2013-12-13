#
# Copyright (C) 2006-2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=watchping
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)
GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Ping a host and run customizable actions (hooks) on timeout/recovery.
  MAINTAINER:=Gui Iribarren <gui@altermundi.net>
endef

define Package/$(PKG_NAME)/description
  Checks reachability of given host(s) through particular interface(s) (e.g. 8.8.8.8 on WAN).
  Action hooks are run from /etc/watchping/*.d/
  Configuration is done in /etc/config/system.
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
