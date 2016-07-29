#!/bin/sh

export PWD_DIR=$(pwd)
export SCRIPTDIR=$(cd "$(dirname "$0")"; pwd)

export BUILDER_DIR=OpenWrt-ImageBuilder-15.05.1-ar71xx-nand.Linux-x86_64
export IPSET_NAME=gfwlist

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

    # Make config files
    mkdir -p $SCRIPTDIR/upload-files/etc/opkg
    cat > $SCRIPTDIR/upload-files/etc/opkg/distfeeds.conf <<FEEDS_EOF
#src/gz chaos_calmer_base http://downloads.openwrt.org/chaos_calmer/15.05.1/ar71xx/nand/packages/base
#src/gz chaos_calmer_luci http://downloads.openwrt.org/chaos_calmer/15.05.1/ar71xx/nand/packages/luci
#src/gz chaos_calmer_packages http://downloads.openwrt.org/chaos_calmer/15.05.1/ar71xx/nand/packages/packages
#src/gz chaos_calmer_routing http://downloads.openwrt.org/chaos_calmer/15.05.1/ar71xx/nand/packages/routing
#src/gz chaos_calmer_telephony http://downloads.openwrt.org/chaos_calmer/15.05.1/ar71xx/nand/packages/telephony
#src/gz chaos_calmer_management http://downloads.openwrt.org/chaos_calmer/15.05.1/ar71xx/nand/packages/management

src/gz chaos_calmer_base http://23.83.236.66:1081/chaos_calmer/15.05.1/ar71xx/nand/packages/base
src/gz chaos_calmer_luci http://23.83.236.66:1081/chaos_calmer/15.05.1/ar71xx/nand/packages/luci
src/gz chaos_calmer_packages http://23.83.236.66:1081/chaos_calmer/15.05.1/ar71xx/nand/packages/packages
src/gz chaos_calmer_routing http://23.83.236.66:1081/chaos_calmer/15.05.1/ar71xx/nand/packages/routing
src/gz chaos_calmer_telephony http://23.83.236.66:1081/chaos_calmer/15.05.1/ar71xx/nand/packages/telephony
src/gz chaos_calmer_management http://23.83.236.66:1081/chaos_calmer/15.05.1/ar71xx/nand/packages/management
FEEDS_EOF

    mkdir -p $SCRIPTDIR/upload-files/root
    cat > $SCRIPTDIR/upload-files/root/ss-install.sh <<INS_EOF
opkg install shadowsocks-libev-spec-polarssl_2.4.8-2_ar71xx.ipk

cat > /etc/init.d/shadowsocks << SS_EOF
#!/bin/sh /etc/rc.common

START=95

SERVICE_USE_PID=1
SERVICE_WRITE_PID=1
SERVICE_DAEMONIZE=1
IPSET_NAME=$IPSET_NAME
CONFIG=/etc/shadowsocks.json

start() {
	#service_start /usr/bin/ss-local -c \$CONFIG -b 0.0.0.0
	service_start /usr/bin/ss-redir -c \$CONFIG -A -u -f /var/run/ss-redir.pid
	service_start /usr/bin/ss-tunnel -c \$CONFIG -A -u -l 2053 -L 8.8.8.8:53 -f /var/run/ss-tunnel.pid

        ipset flush \$IPSET_NAME || ipset -N \$IPSET_NAME iphash
        iptables -t nat -A PREROUTING -p tcp -m set --match-set \$IPSET_NAME dst -j REDIRECT --to-port 1081
        iptables -t nat -A OUTPUT -p tcp -m set --match-set \$IPSET_NAME dst -j REDIRECT --to-port 1081
}

stop() {
        iptables -t nat -D PREROUTING -p tcp -m set --match-set \$IPSET_NAME dst -j REDIRECT --to-port 1081
        iptables -t nat -D OUTPUT -p tcp -m set --match-set \$IPSET_NAME dst -j REDIRECT --to-port 1081
        ipset flush \$IPSET_NAME

	service_stop /usr/bin/ss-local
	service_stop /usr/bin/ss-redir
	service_stop /usr/bin/ss-tunnel
}
SS_EOF

grep -q 'conf-dir=/etc/dnsmasq.d' /etc/dnsmasq.conf || echo 'conf-dir=/etc/dnsmasq.d' >> /etc/dnsmasq.conf
mkdir -p /etc/dnsmasq.d
cd /etc/dnsmasq.d
# Make file gfwlist.txt
wget --no-check-certificate https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt -O gfwlist.txt

# Make file gfwlist2dnsmasq.py
python gfwlist2dnsmasq.py
INS_EOF

    # Make WNDR4300 Image
    cd $SCRIPTDIR/$BUILDER_DIR
    BASE="luci luci-theme-bootstrap luci-i18n-base-zh-cn"
    TOOLS="nano bind-dig"
    APPS="luci-i18n-ddns-zh-cn luci-i18n-wol-zh-cn luci-i18n-upnp-zh-cn luci-i18n-qos-zh-cn luci-i18n-commands-zh-cn"

    GFW="-dnsmasq dnsmasq-full ipset iptables-mod-nat-extra"
    SDK="python python-pip"
    SMB="luci-app-samba luci-app-hd-idle kmod-nls-utf8 kmod-usb-ohci kmod-usb-storage kmod-usb-storage-extras kmod-usb-uhci"

    PACKS="${BASE} ${TOOLS} ${APPS} ${GFW} ${SDK}"
    echo "make image PROFILE=WNDR4300 PACKAGES=$PACKS FILES=$SCRIPTDIR/upload-files/"
    make image PROFILE=WNDR4300 PACKAGES="$PACKS" FILES=$SCRIPTDIR/upload-files/
fi

cat > bin/ar71xx/tftp-upload <<EOF
connect 192.168.1.1
binary
put openwrt-15.05.1-ar71xx-nand-wndr4300-ubi-factory.img
quit
EOF
