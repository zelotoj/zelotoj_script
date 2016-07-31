#!/bin/sh

export PWD_DIR=$(pwd)
export SCRIPTDIR=$(cd "$(dirname "$0")"; pwd)

NET_5G=$(devmem 0x180600b0)

if [ "${NET_5G}" = "0x002F051A" ]; then
    echo '5G网卡异常，请关闭电源1分钟'
else
    echo '5G网卡正常'
fi
