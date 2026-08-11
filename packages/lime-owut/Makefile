include ../../libremesh.mk

# owut is available since openwrt-24.10
PKG_AVAILABLE:=1
OW_BRANCH:=$(shell echo $$(grep -m1 -o "releases/.*" \
	$(TOPDIR)/include/version.mk || echo "main") | \
	cut -d"/" -f2 | cut -d"." -f1,2 )

ifneq ($(OW_BRANCH),main)
  ifeq ($(shell test $$(echo $(OW_BRANCH) | cut -d"." -f1) -lt 24; echo $$?),0)
    PKG_AVAILABLE:=0
  endif
endif

ifeq ($(PKG_AVAILABLE),1)

	define Package/$(PKG_NAME)
		TITLE:=$(PKG_NAME) allows to use owut OpenWrt Upgrade Tool in LibreMesh
		CATEGORY:=LibreMesh
		URL:=http://libremesh.org
		DEPENDS:=+owut
		PKGARCH:=all
	endef

	define Package/$(PKG_NAME)/postinst
#!/bin/sh
# Preserve the complete opkg status if CONFIG_CLEAN_IPKG=y
grep -q CONFIG_CLEAN_IPKG=y $${TOPDIR}/.config || exit 0
[ -f $${IPKG_INSTROOT}/usr/lib/opkg/status ] || exit 0

cp $${IPKG_INSTROOT}/usr/lib/opkg/status $${IPKG_INSTROOT}/etc/opkg/
cat << EOF > $${IPKG_INSTROOT}/etc/uci-defaults/99_owut-packagelist
#!/bin/sh
rm /usr/lib/opkg/status
ln -s /etc/opkg/status /usr/lib/opkg/status
EOF
	endef

	$(eval $(call BuildPackage,$(PKG_NAME)))

endif
