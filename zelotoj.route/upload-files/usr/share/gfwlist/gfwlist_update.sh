#!/bin/sh

export PWD_DIR=$(pwd)
export SCRIPTDIR=$(cd "$(dirname "$0")"; pwd)

echo ""
echo "正在更新 gfwlist..."
python $SCRIPTDIR/gfwlist2dnsmasq.py > /dev/null
if [ -f dnsmasq_list.conf ]; then
    if [ $(du dnsmasq_list.conf | awk '{print $1}') -gt 200 ]; then
        grep -v '=/.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}/' dnsmasq_list.conf > gfwlist.conf
        rm dnsmasq_list.conf
        echo "更新完成"
    fi
fi
echo ""
