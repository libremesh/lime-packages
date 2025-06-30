include ../../libremesh.mk  

define Package/$(PKG_NAME)
  SECTION:=lime
  CATEGORY:=LibreMesh
  TITLE:=odhcpd leases module for shared-state
  DEPENDS:=+lua +luci-lib-jsonc +shared-state-async +odhcpd
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
Synchronize external DHCP leases between LibreMesh nodes by
watching odhcpd’s lease file, publishing updates over shared-state-async
and injecting remote leases locally.
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
