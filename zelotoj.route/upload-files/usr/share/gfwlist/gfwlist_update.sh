#!/bin/sh

export PWD_DIR=$(pwd)
export SCRIPTDIR=$(cd "$(dirname "$0")"; pwd)

cd /tmp

python $SCRIPTDIR/gfwlist2dnsmasq.py > /dev/nul
mv -f dnsmasq_list.conf /etc/dnsmasq.d/dnsmasq_list.conf && echo '更新完成'
