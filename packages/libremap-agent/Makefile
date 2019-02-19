#
# Copyright 2013 Patrick Grimm <patrick@lunatiki.de>
# Copyright 2013 André Gaul <gaul@web-yard.de>
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=libremap-agent
PKG_VERSION:=0.1.9
PKG_RELEASE=$(PKG_SOURCE_VERSION)


PKG_SOURCE_URL:=git://github.com/aparcar/libremap-agent-openwrt.git
PKG_SOURCE_VERSION:=054133cd07b6ca77bba32537ad2141a193a94111
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION).tar.gz

include $(INCLUDE_DIR)/package.mk

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR)/luasrc
endef

define Package/luci-lib-libremap/default
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=8. Libraries
  URL:=https://github.com/libremap/libremap-agent-openwrt
endef


define Package/luci-lib-libremap
  $(call Package/luci-lib-libremap/default)
  DEPENDS:=+luci-base +luci-lib-json +luci-lib-httpclient +libuci-lua
  TITLE:=LibreMap base library
endef

define Package/luci-lib-libremap/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/libremap
	$(CP) $(PKG_BUILD_DIR)/luasrc/libremap.lua $(1)/usr/lib/lua/luci/
	$(CP) $(PKG_BUILD_DIR)/luasrc/libremap/util.lua $(1)/usr/lib/lua/luci/libremap/
endef

$(eval $(call BuildPackage,luci-lib-libremap))


# based on collectd Makefile
# parameters:
#  * package name: luci-lib-libremap-$(1)
#  * package title: LibreMap $(2) plugin
#  * dependencies (additional to luci-lib-libremap): $(3)
#  plugin file has to be placed in luasrc/libremap/plugins/$(1).lua
define BuildPlugin
  define Package/luci-lib-libremap-$(1)
    $$(call Package/luci-lib-libremap/default)
    TITLE:=LibreMap $(2) plugin
    DEPENDS:=luci-lib-libremap $(3)
  endef
  define Package/luci-lib-libremap-$(1)/install
	$(INSTALL_DIR) $$(1)/usr/lib/lua/luci/libremap/plugins
	$(CP) $(PKG_BUILD_DIR)/luasrc/libremap/plugins/$(1).lua $$(1)/usr/lib/lua/luci/libremap/plugins
  endef
  $$(eval $$(call BuildPackage,luci-lib-libremap-$(1)))
endef

$(eval $(call BuildPlugin,altermap,AlterMap,))
$(eval $(call BuildPlugin,contact,contact,))
$(eval $(call BuildPlugin,freifunk,Freifunk,))
$(eval $(call BuildPlugin,location,location,))
$(eval $(call BuildPlugin,olsr,olsr,))
$(eval $(call BuildPlugin,system,system,))
$(eval $(call BuildPlugin,wireless,wireless,))
$(eval $(call BuildPlugin,babel,babel,))
$(eval $(call BuildPlugin,bmx6,bmx6,))
$(eval $(call BuildPlugin,qmp,qmp,))

define Package/libremap-agent
  SECTION:=utilities
  CATEGORY:=Utilities
  URL:=https://github.com/libremap/libremap-agent-openwrt
  TITLE:=LibreMap router database and map submit agent
  DEPENDS:=+luci-lib-libremap
endef

define Package/libremap-agent/install
	$(INSTALL_DIR) $(1)/
	$(CP) ./files/* $(1)/
endef

# register cronjob
define Package/libremap-agent/postinst
#!/bin/sh
if [ -z $${IPKG_INSTROOT} ] ; then
	( . /etc/uci-defaults/80_libremap-agent ) && rm -f /etc/uci-defaults/80_libremap-agent
	/etc/init.d/libremap-agent enable
fi
exit 0
endef

# unregister cronjob
define Package/libremap-agent/prerm
#!/bin/sh
if [ -z $${IPKG_INSTROOT} ] ; then
	sed -ie '/libremap-agent/d' /etc/crontabs/root
	/etc/init.d/libremap-agent disable
fi
exit 0
endef

$(eval $(call BuildPackage,libremap-agent))

