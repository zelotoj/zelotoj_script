#!/bin/sh

export PWD_DIR=$(pwd)
export SCRIPTDIR=$(cd "$(dirname "$0")"; pwd)
export SCRIPTNAME=$(basename "$0")

logger -t $SCRIPTNAME "start"
$SCRIPTDIR/gfwlist_update.sh
if [ -f gfwlist.conf ]; then
    if [ $(du gfwlist.conf | awk '{print $1}') -gt 200 ]; then
        mkdir -p /etc/dnsmasq.d
        cp -f gfwlist.conf /etc/dnsmasq.d/gfwlist.conf
        logger -t $SCRIPTNAME "ok"
        /etc/init.d/auto_ss_gfwlist restart
    fi
fi
logger -t $SCRIPTNAME "complete"
