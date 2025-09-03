# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2006-2013 OpenWrt.org

include ../../libremesh.mk

define Package/$(PKG_NAME)
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=$(PKG_NAME) falls back to a last-known-good config after an ill-fated reboot.
  MAINTAINER:=Gui Iribarren <gui@altermundi.net>
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
  When you run $(PKG_NAME) specifying a grace time, it makes a backup of /etc at that point,
  and after the grace time reboots the system. At the next boot, it waits again for a timeout;
  if you can't login and delete the backup, it will restore it and reboot.
  This mechanism makes it possible to run $(PKG_NAME), try risky operations (like restarting
  the network), and if something goes wrong, just wait for the fallback timeout.
  Even more, you can make actual changes to /etc config and reboot. If it comes back up right,
  you can login and delete the backup. If something went wrong with the new /etc, just wait
  for the revert timeout.
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
