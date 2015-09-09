# Copyright (C) 2006-2014 libre-mesh.org
# This is free software, licensed under the GNU General Public License v3.

include $(TOPDIR)/rules.mk

PKG_NAME:=lime-eb-ip-tables
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  TITLE:=libre-mesh iptables/ebtables support 
  CATEGORY:=LiMe
  MAINTAINER:=Pau Escrich <p4u@dabax.net>
  URL:=http://libre-mesh.org
  DEPENDS:= +kmod-ipt-nat +kmod-ipt-nat-extra +kmod-ebtables +iptables +ebtables
endef

define Package/$(PKG_NAME)/description
	Metapackage depending on all the required to have iptables/ebtables support
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
