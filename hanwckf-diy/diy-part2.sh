#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# Modify default IP
#sed -i 's/192.168.1.1/192.168.50.5/g' package/base-files/files/bin/config_generate
##-----------------Del duplicate packages------------------
rm -rf feeds/packages/net/open-app-filter
##-----------------Add OpenClash meta core------------------
curl -sL -m 30 --retry 2 https://raw.githubusercontent.com/vernesong/OpenClash/core/master/meta/clash-linux-arm64.tar.gz -o /tmp/clash.tar.gz
tar zxvf /tmp/clash.tar.gz -C /tmp >/dev/null 2>&1
chmod +x /tmp/clash >/dev/null 2>&1
mkdir -p feeds/luci/applications/luci-app-openclash/root/etc/openclash/core
mv /tmp/clash feeds/luci/applications/luci-app-openclash/root/etc/openclash/core/clash_meta >/dev/null 2>&1
rm -rf /tmp/clash.tar.gz >/dev/null 2>&1
##-----------------Delete DDNS's examples-----------------
sed -i '/myddns_ipv4/,$d' feeds/packages/net/ddns-scripts/files/etc/config/ddns
##-----------------Manually set CPU frequency for MT7981B-----------------
sed -i '/"mediatek"\/\*|\"mvebu"\/\*/{n; s/.*/\tcpu_freq="1.3GHz" ;;/}' package/emortal/autocore/files/generic/cpuinfo
##-----------------Patch block.mk: restore missing dm-mod.ko for kmod-dm build-----------------
# External repo (immortalwrt-mt798x-hanwckf) has CONFIG_BLK_DEV_DM=y (dm builtin) but dropped
# dm-mod.ko from KernelPackage/dm FILES, so when CONFIG_PACKAGE_kmod-dm=y is selected the
# packer fails with 'dm-mod.ko is missing'. Restore upstream behavior:
sed -i 's/\tCONFIG_BLK_DEV_DM=y/\tCONFIG_BLK_DEV_DM=m/' package/kernel/linux/modules/block.mk
sed -i 's@\$(LINUX_DIR)/drivers/md/dm-crypt.ko@\$(LINUX_DIR)/drivers/md/dm-mod.ko \n    \$(LINUX_DIR)/drivers/md/dm-crypt.ko@' package/kernel/linux/modules/block.mk
sed -i 's@AutoLoad,30,dm-log dm-region-hash dm-mirror dm-crypt@AutoLoad,30,dm-mod dm-log dm-region-hash dm-mirror dm-crypt@' package/kernel/linux/modules/block.mk
grep -n 'dm-mod' package/kernel/linux/modules/block.mk || true
