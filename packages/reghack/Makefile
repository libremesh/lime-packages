#
# Copyright (C) 2006-2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

LIBRE_MESH_NAME:=Libre Mesh
LIBRE_MESH_PREFIX:=lime

GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

PKG_NAME:=reghack
PKG_VERSION:=20140207
PKG_RELEASE=$(GIT_COMMIT_TSTAMP)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)/template
	CATEGORY:=LiMe
	MAINTAINER:=Gui Iribarren <gui@altermundi.net>
endef

define Package/$(PKG_NAME)
	$(call Package/$(PKG_NAME)/template)
	TITLE:=Regulatory domain unlocker
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
	$(call Build/Prepare/Default)
endef

define Build/Compile
	$(TARGET_CC) -o $(PKG_BUILD_DIR)/reghack $(PKG_BUILD_DIR)/reghack.c
	$(HOSTCC) -o $(STAGING_DIR_HOST)/bin/reghack $(PKG_BUILD_DIR)/reghack.c
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/reghack $(1)/usr/bin/reghack
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh

workDir="/tmp/reghack-apply/"
modules="ath cfg80211"
modulesDir="$$IPKG_INSTROOT/lib/modules/"
etcDir="$$IPKG_INSTROOT/etc/reghack/"
statusFile="$${etcDir}/status"
logFile="$${etcDir}/log"
hackOk=0

mkdir -p $${workDir}
mkdir -p $${etcDir}

for module in $${modules} ; do
	cp $${modulesDir}/*/$${module}.ko $${workDir}
	reghack $${workDir}/$${module}.ko >> $${logFile} 2>&1
	hackOk=$$((hackOk+$$?))
done

if [ "$${hackOk}" -eq 0 ]
	then
		mv -f $${workDir}/*.ko "$${modulesDir}"/*/
		echo "RegHack succeded on $${modules}" > $${statusFile}
	else
		echo "RegHack failed" > $${statusFile}
fi

rm -rf $${workDir}

exit 0

endef

$(eval $(call BuildPackage,$(PKG_NAME)))
