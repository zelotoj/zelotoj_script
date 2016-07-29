#!/bin/sh

export PWD_DIR=$(pwd)
export SCRIPTDIR=$(cd "$(dirname "$0")"; pwd)

cd $SCRIPTDIR

opkg install shadowsocks-libev-spec-polarssl_2.4.8-2_ar71xx.ipk

cat > /etc/init.d/shadowsocks << SS_EOF
#!/bin/sh /etc/rc.common

START=95

SERVICE_USE_PID=1
SERVICE_WRITE_PID=1
SERVICE_DAEMONIZE=1
CONFIG=/etc/shadowsocks.json

start() {
	#service_start /usr/bin/ss-local -c \$CONFIG -b 0.0.0.0
	service_start /usr/bin/ss-redir -c \$CONFIG -A -u -f /var/run/ss-redir.pid
	service_start /usr/bin/ss-tunnel -c \$CONFIG -A -u -l 2053 -L 8.8.8.8:53 -f /var/run/ss-tunnel.pid

    ipset flush gfwlist || ipset -N gfwlist iphash
    iptables -t nat -A PREROUTING -p tcp -m set --match-set gfwlist dst -j REDIRECT --to-port 1081
    iptables -t nat -A OUTPUT -p tcp -m set --match-set gfwlist dst -j REDIRECT --to-port 1081
}

stop() {
    iptables -t nat -D PREROUTING -p tcp -m set --match-set gfwlist dst -j REDIRECT --to-port 1081
    iptables -t nat -D OUTPUT -p tcp -m set --match-set gfwlist dst -j REDIRECT --to-port 1081
    ipset flush gfwlist

	#service_stop /usr/bin/ss-local
	service_stop /usr/bin/ss-redir
	service_stop /usr/bin/ss-tunnel
}
SS_EOF

grep -q 'conf-dir=/etc/dnsmasq.d' /etc/dnsmasq.conf || echo 'conf-dir=/etc/dnsmasq.d' >> /etc/dnsmasq.conf

if [ ! -d /etc/dnsmasq.d ]; then
    mkdir -p /etc/dnsmasq.d
fi

# Make file gfwlist2dnsmasq.py
python gfwlist2dnsmasq.py
