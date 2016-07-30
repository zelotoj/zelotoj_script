#!/bin/sh

export PWD_DIR=$(pwd)
export SCRIPTDIR=$(cd "$(dirname "$0")"; pwd)

export BUILDER_DIR=OpenWrt-ImageBuilder-15.05.1-ar71xx-nand.Linux-x86_64

# Download OpenWrt-ImageBuilder
if [ ! -f $BUILDER_DIR.tar.bz2 ]; then
    wget https://downloads.openwrt.org/chaos_calmer/15.05.1/ar71xx/nand/$BUILDER_DIR.tar.bz2 -O $BUILDER_DIR.tar.bz2
fi

if [ ! -d $BUILDER_DIR ]; then
    tar -xjf $BUILDER_DIR.tar.bz2
fi

if [ -d $BUILDER_DIR ]; then
    cd $SCRIPTDIR/$BUILDER_DIR
    make info

    # Change 128M ROM Patch
    if [ ! -f target/linux/ar71xx/image/Makefile.bak ]; then
        mv target/linux/ar71xx/image/Makefile target/linux/ar71xx/image/Makefile.bak
    fi
    sed 's/23552k(ubi)/121856k(ubi)/g' target/linux/ar71xx/image/Makefile.bak > target/linux/ar71xx/image/Makefile

    # Make file gfwlist.txt
    cd $SCRIPTDIR/upload-files/root
    python gfwlist2dnsmasq.py
    if [ -f dnsmasq_list.conf ]; then
        mkdir -p $SCRIPTDIR/upload-files/etc/dnsmasq.d
        mv dnsmasq_list.conf $SCRIPTDIR/upload-files/etc/dnsmasq.d/dnsmasq_list.conf
    fi

    # Make WNDR4300 Image
    cd $SCRIPTDIR/$BUILDER_DIR
    BASE="luci luci-theme-bootstrap luci-i18n-base-zh-cn"
    TOOLS="openssh-sftp-server nano bind-dig htop iftop iperf curl whereis"
    APPS="luci-i18n-ddns-zh-cn luci-i18n-wol-zh-cn luci-i18n-upnp-zh-cn luci-i18n-qos-zh-cn luci-i18n-commands-zh-cn luci-i18n-privoxy-zh-cn"

    GFW="-dnsmasq dnsmasq-full ip ipset iptables-mod-nat-extra iptables-mod-tproxy libpolarssl"
    SDK="python python-pip"
    #SMB="luci-app-samba luci-app-hd-idle kmod-nls-utf8 kmod-usb-ohci kmod-usb-storage kmod-usb-storage-extras kmod-usb-uhci"
    #VPN="strongswan"

    PACKS="${BASE} ${TOOLS} ${APPS} ${GFW} ${SDK} ${SMB} ${VPN}"
    make image PROFILE=WNDR4300 PACKAGES="$PACKS" FILES=$SCRIPTDIR/upload-files/
    echo "make image PROFILE=WNDR4300 PACKAGES=$PACKS FILES=$SCRIPTDIR/upload-files/"
fi

cd $SCRIPTDIR/$BUILDER_DIR/bin/ar71xx

cat > tftp-upload.sh <<EOF
#!/bin/sh
cat > tftp-upload.cmd <<CMD_EOF
connect 192.168.1.1
binary
put openwrt-15.05.1-ar71xx-nand-wndr4300-ubi-factory.img
quit
CMD_EOF

tftp < tftp-upload.cmd
EOF
chmod a+x tftp-upload.sh
