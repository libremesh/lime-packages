# Provide ping6 compatibility between Openwrt master and future releases based
# on it with OpenWrt 19.07.X and 18.06.X
# Other attempts using LINUX_X_Y variable proven to not work reliably and where
# even uglier.
# Include this file in your makefile and the use the PING6_PACKAGE
# and PING6_SYMLINK as you need.
# See shared-state and lime-debug for usage examples.

# Just in case the the OpenWrt source code is a shallow clone
$(shell git -C $(TOPDIR) fetch --unshallow || true)

# In case the iputils-ping6 removal commit
# 98b3526bf23e8d1b48939c937c9b12e4f2160415 is ancestor of current commit
# ping6 is provided by iputils-ping + PING_LEGACY_SYMLINKS.
PING6_PACKAGE=iputils-ping6
PING6_SYMLINK=PACKAGE_iputils-ping6
ifeq ($(shell git -C $(TOPDIR) merge-base --is-ancestor 98b3526bf23e8d1b48939c937c9b12e4f2160415 HEAD ; echo $$?),0)
PING6_PACKAGE=iputils-ping
PING6_SYMLINK=PING_LEGACY_SYMLINKS
endif
