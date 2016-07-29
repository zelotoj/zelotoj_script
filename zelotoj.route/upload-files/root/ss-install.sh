#!/bin/sh

export PWD_DIR=$(pwd)
export SCRIPTDIR=$(cd "$(dirname "$0")"; pwd)

cd $SCRIPTDIR

opkg install shadowsocks-libev-spec-polarssl_2.4.8-2_ar71xx.ipk

grep -q 'conf-dir=/etc/dnsmasq.d' /etc/dnsmasq.conf || echo 'conf-dir=/etc/dnsmasq.d' >> /etc/dnsmasq.conf

if [ ! -d /etc/dnsmasq.d ]; then
    mkdir -p /etc/dnsmasq.d
fi
