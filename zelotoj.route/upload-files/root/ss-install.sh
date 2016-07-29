#!/bin/sh

export PWD_DIR=$(pwd)
export SCRIPTDIR=$(cd "$(dirname "$0")"; pwd)

cd $SCRIPTDIR

opkg install shadowsocks-libev-spec-polarssl_2.4.8-2_ar71xx.ipk

grep -q 'conf-dir=/etc/dnsmasq.d' /etc/dnsmasq.conf || echo 'conf-dir=/etc/dnsmasq.d' >> /etc/dnsmasq.conf

if [ ! -d /etc/dnsmasq.d ]; then
    mkdir -p /etc/dnsmasq.d
fi

cat > /etc/rc.local <<EOF
# Put your custom commands here that should be executed once
# the system init finished. By default this file does nothing.

/etc/init.d/auto_ss_gfwlist restart

exit 0
EOF
