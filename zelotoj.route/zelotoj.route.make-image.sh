#!/bin/sh

export PWD_DIR=$(pwd)
export SCRIPTDIR=$(cd "$(dirname "$0")"; pwd)

export BUILDER_DIR=OpenWrt-ImageBuilder-15.05.1-ar71xx-nand.Linux-x86_64

# Download OpenWrt-ImageBuilder
if [ ! -f OpenWrt-ImageBuilder.tar.bz2 ]; then
    wget https://downloads.openwrt.org/chaos_calmer/15.05.1/ar71xx/nand/$BUILDER_DIR.tar.bz2 -O $BUILDER_DIR.tar.bz2
fi

if [ ! -d OpenWrt-ImageBuilder ]; then
    tar -xjf $BUILDER_DIR.tar.bz2
fi

cd $BUILDER_DIR
make info

# Change 128M ROM Patch
if [ ! -f target/linux/ar71xx/image/Makefile.bak ]; then
    mv target/linux/ar71xx/image/Makefile target/linux/ar71xx/image/Makefile.bak
    sed -e 's/wndr4300_mtdlayout=mtdparts=ar934x-nfc:256k(u-boot)ro,256k(u-boot-env)ro,256k(caldata),512k(pot),2048k(language),512k(config),3072k(traffic_meter),2048k(kernel),23552k(ubi),25600k@0x6c0000(firmware),256k(caldata_backup),-(reserved)/wndr4300_mtdlayout=mtdparts=ar934x-nfc:256k(u-boot)ro,256k(u-boot-env)ro,256k(caldata),512k(pot),2048k(language),512k(config),3072k(traffic_meter),2048k(kernel),121856k(ubi),25600k@0x6c0000(firmware),256k(caldata_backup),-(reserved)/g' target/linux/ar71xx/image/Makefile.bak 1>target/linux/ar71xx/image/Makefile
fi

# Make WNDR4300 Image
make image PROFILE=WNDR4300 PACKAGES="luci luci-theme-bootstrap luci-i18n-base-zh-cn dnsmasq-full"

cat > opkg.conf <<EOF
#src/gz chaos_calmer_base http://downloads.openwrt.org/chaos_calmer/15.05/ar71xx/nand/packages/base
src/gz chaos_calmer_base http://23.83.236.66:1081/chaos_calmer/15.05.1/ar71xx/nand/packages/base
src/gz chaos_calmer_luci http://23.83.236.66:1081/chaos_calmer/15.05.1/ar71xx/nand/packages/luci
src/gz chaos_calmer_packages http://23.83.236.66:1081/chaos_calmer/15.05.1/ar71xx/nand/packages/packages
src/gz chaos_calmer_routing http://23.83.236.66:1081/chaos_calmer/15.05.1/ar71xx/nand/packages/routing
src/gz chaos_calmer_telephony http://23.83.236.66:1081/chaos_calmer/15.05.1/ar71xx/nand/packages/telephony
src/gz chaos_calmer_management http://23.83.236.66:1081/chaos_calmer/15.05.1/ar71xx/nand/packages/management
EOF
