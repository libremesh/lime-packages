# SPDX-License-Identifier: GPL-2.0-or-later
#
# Copyright (C) 2018 Pau Escrich <p4u@dabax.net>

include ../../libremesh.mk

PKG_VERSION:=0.0.1
PKG_RELEASE:=1
PKG_LICENSE:=GPL-2.0+

define Package/$(PKG_NAME)
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Routing and Redirection
  TITLE:=bmx7 distributed DNS system
  URL:=http://bmx6.net
  MAINTAINER:=Pau Escrich <p4u@dabax.net>
  PKGARCH:=all
  DEPENDS:=+bmx7 +bmx7-sms +luci-lib-nixio
endef

define Package/$(PKG_NAME)/config
  select CONFIG_BUSYBOX_CONFIG_CROND
  select CONFIG_BUSYBOX_CONFIG_CRONTAB
endef

define Package/$(PKG_NAME)/description
 Distributed DNS system using bmx7 sms plugin
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
