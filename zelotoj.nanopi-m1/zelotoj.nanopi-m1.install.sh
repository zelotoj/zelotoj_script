#!/bin/sh

export PWD_DIR=$(pwd)
export SCRIPTDIR=$(cd "$(dirname "$0")"; pwd)

# Install common tools
apt-get update && apt-get upgrade -y
apt-get install htop iftop dnsutils iperf ntpdate

# Install python
apt-get install python-dev
wget https://raw.github.com/pypa/pip/master/contrib/get-pip.py
python get-pip.py
