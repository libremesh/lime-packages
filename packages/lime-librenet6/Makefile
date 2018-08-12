include $(TOPDIR)/rules.mk

PKG_NAME:=lime-librenet6
PKG_VERSION:=0.1
PKG_RELEASE:=1

PKG_MAINTAINER:=Paul Spooren <mail@aparcar.org>

include $(INCLUDE_DIR)/package.mk

define Package/lime-librenet6/Default
  SECTION:=lime
  CATEGORY:=LiMe
  TITLE:=LibreMesh LibreNet6 autosetup
  PKGARCH:=all
  DEPENDS:=tinc lime-proto-babeld
endef

define Package/lime-librenet6/description
	Autoamtically install required packaged to connect to
	librenet6.libremesh.org and wait for an invitation link.

	Request an invitation at librenet6@aparcar.org
endef

Build/Compile=

define Package/lime-librenet6/install
		$(INSTALL_DIR) $(1)/
		$(CP) -r files/* $(1)/
endef

$(eval $(call BuildPackage,lime-librenet6))
