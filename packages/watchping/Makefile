# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2006-2013 OpenWrt.org

include ../../libremesh.mk

define Package/$(PKG_NAME)
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Ping a host and run customizable actions (hooks) on timeout/recovery.
  MAINTAINER:=Gui Iribarren <gui@altermundi.net>
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
  Checks reachability of given host(s) through particular interface(s) (e.g. 8.8.8.8 on WAN).
  Action hooks are run from /etc/watchping/*.d/
  Configuration is done in /etc/config/system.
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
