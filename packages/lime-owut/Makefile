include ../../libremesh.mk

OW_BRANCH:=$(shell top="$(TOPDIR)" && grep VERSION_NUMBER:= $${top}/include/version.mk | \
	tail -n1 | grep -E -o '[0-9]+\.[0-9]+' || echo main)

PKG_AVAILABLE:=$(shell b=$(OW_BRANCH) && if [ $$b == 'main' ]; then echo 1; \
	elif [ $${b:0:2} -gt 23 ]; then echo 1; else echo 0; fi)

ifeq ($(PKG_AVAILABLE),1)

define Package/$(PKG_NAME)
	TITLE:=$(PKG_NAME) allows to use owut OpenWrt Upgrade Tool in LibreMesh
	CATEGORY:=LibreMesh
	URL:=http://libremesh.org
	DEPENDS:=+owut
  PKGARCH:=all
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

endif
