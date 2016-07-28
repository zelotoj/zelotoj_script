#!/bin/sh

export PWD_DIR=$(pwd)
export SCRIPTDIR=$(cd "$(dirname "$0")"; pwd)

# Install network tools
apt-get update && apt-get upgrade -y
apt-get install htop iftop dnsutils iperf

# Install python
apt-get install python-dev
wget https://raw.github.com/pypa/pip/master/contrib/get-pip.py
python get-pip.py

# Install libsodium
wget https://download.libsodium.org/libsodium/releases/LATEST.tar.gz
tar zxf LATEST.tar.gz
cd libsodium*
./configure
make && make install

echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf
ldconfig

# Install shadowsocks
wget --no-check-certificate https://raw.githubusercontent.com/tennfy/shadowsocks-libev/master/debian_shadowsocks_tennfy.sh
chmod a+x debian_shadowsocks_tennfy.sh
bash debian_shadowsocks_tennfy.sh

# Make file /root/gfwlist.txt
wget --no-check-certificate https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt

# Make file /etc/rc.local
cat > /etc/rc.local << EOF
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "#exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

/usr/bin/socat -ly tcp4-listen:1053,reuseaddr,fork UDP:8.8.8.8:53 &

#nohup /root/net_speeder venet0:0 "ip" >/dev/null 2>&1 &

python /root/openwrt/update.py

exit 0
EOF
