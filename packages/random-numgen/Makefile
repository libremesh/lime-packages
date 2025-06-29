# This is free software, licensed under the GNU General Public License v3.
# See /LICENSES for more information.
#

include ../../libremesh.mk

PKG_VERSION:=0.0.1
PKG_RELEASE:=1

PKG_MAINTAINER:=Ilario Gelmetti <ilario@sindominio.net>
PKG_LICENSE:=GPL-3.0-or-later

define Package/random-numgen
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Generates a random number 0-65535
  PKGARCH:=all
endef

define Package/random-numgen/description
  Offers an alternative to the RANDOM shell variable,
  generating a pseudo-random integer number from 0 to
  65535 using /dev/urandom as a random data source.
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
