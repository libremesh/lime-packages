#
# Copyright (C) 2012 Gui Iribarren
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=watchping
PKG_VERSION:=$(shell hg log --template "{date|shortdate}-{rev}\n" -l 1 .)
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/watchping
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Ping a host and run customizable actions (hooks) on timeout/recovery.
  MAINTAINER:=Gui Iribarren <gui@altermundi.net>
endef

define Package/watchping/description
  Checks reachability of given host(s) through particular interface(s) (e.g. 8.8.8.8 on WAN).
  Action hooks are run from /etc/watchping/*.d/
  Configuration is done in /etc/config/system.
endef

define Build/Compile
endef

define Package/watchping/install
	$(INSTALL_DIR) $(1)/
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,watchping))
