#
# This is an OpenWrt package Makefile for ethtool-tunables
# Package name uses a hyphen; UCI namespace and file names use an underscore.
#   Package: ethtool-tunables
#   UCI config: /etc/config/ethtool_tunables
#
include $(TOPDIR)/rules.mk

PKG_NAME:=ethtool-tunables
PKG_RELEASE:=1
PKG_LICENSE:=MIT
PKG_MAINTAINER:=Nicolas Vandamme <n.vandamme@gmail.com>

# Dummy source (no upstream tarball). The package installs files/ directly.
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/ethtool-tunables
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Apply ethtool/ip tunables at boot and hotplug
  URL:=https://github.com/nvandamme/openwrt-ethtool-tunables
  DEPENDS:=+ethtool +ip-tiny +ubus +uci +busybox
endef

define Package/ethtool-tunables/description
Apply ethtool/ip tunables at boot (coldplug) and on net hotplug, after static device renames and before netifd.
The UCI namespace is 'ethtool_tunables'.  See /usr/share/doc/ethtool-tunables/README.md.
endef

# Mark the UCI file as a conffile (so it survives upgrades)
define Package/ethtool-tunables/conffiles
/etc/config/ethtool_tunables
endef

# No real build; keep the default stagedir
define Build/Configure
endef
define Build/Compile
endef

define Package/ethtool-tunables/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/etc/hotplug.d/net
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DIR) $(1)/usr/share/doc/ethtool-tunables

	# The init script, hotplug helper and default config are expected
	# to be dropped into files/ by the developer before packaging.
	# Example (uncomment when the files are present in files/):
	# $(INSTALL_BIN) ./etc/init.d/ethtool_tunables $(1)/etc/init.d/ethtool_tunables
	# $(INSTALL_BIN) ./etc/hotplug.d/net/00-01-ethtool_tunables $(1)/etc/hotplug.d/net/00-01-ethtool_tunables
	# $(INSTALL_CONF) ./etc/config/ethtool_tunables $(1)/etc/config/ethtool_tunables

	# Always include README
	$(INSTALL_DATA) ./README.md $(1)/usr/share/doc/ethtool-tunables/README.md
endef

$(eval $(call BuildPackage,ethtool-tunables))
