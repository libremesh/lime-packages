#
# Copyright (C) 2019 Santiago Piccinini <spiccinini@altermundi.net>
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

PKG_NAME:=safe-upgrade
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=$(PKG_NAME) provides a deferable reboot.
  MAINTAINER:=Santiago Piccinini <spiccinini@altermundi.net>
  DEPENDS:=+lua-argparse
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	This $(PKG_NAME) provides a deferable reboot mechanism. The system
	will be rebooted when the uptime of the system reach a specified amount
	of seconds and if /tmp/deferable-reboot.defer file does not contain a
	number that is greater than the current uptime.
	This way if anyone wants to postpone the reboot, the way is to store the
	next checkpoint in seconds. For example if the system must not reboot from
	now and up to 120 seconds in the future then something like this can be donde
	awk '{print $1 + 120}' /proc/uptime > /tmp/deferable-reboot.defer
endef

define Build/Configure
endef

define Build/Compile
	@rm -rf ./build || true
	@mkdir ./build
	$(CP) ./files ./build
	$(FIND) ./build -name '*.sh' -exec sed -i '/^\s*#\[Doc\]/d' {} +
	$(FIND) ./build -name '*.lua' -exec sed -i '/^\s*--!.*/d' {} +
endef


define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
