#!/bin/sh /etc/rc.common
START=97
STOP=10

boot() {
	return 0
}

reload() {
	restart
	return 0
}

restart() {
	stop
	sleep 1
	start
}

start() {
	date >> /tmp/test.log
	echo 'start begin' >> /tmp/test.log
	ipset flush gfwlist || ipset -N gfwlist iphash
    iptables -t nat -A PREROUTING -p tcp -m set --match-set gfwlist dst -j REDIRECT --to-port 1081
    iptables -t nat -A OUTPUT -p tcp -m set --match-set gfwlist dst -j REDIRECT --to-port 1081
	service_start /usr/bin/ss-redir -c /etc/shadowsocks.json -A -u -f /var/run/ss-redir.pid
	service_start /usr/bin/ss-tunnel -c /etc/shadowsocks.json -A -u -l 2053 -L 8.8.8.8:53 -f /var/run/ss-tunnel.pid

	/etc/init.d/dnsmasq restart
	echo 'start end' >> /tmp/test.log
}

stop() {
	date >> /tmp/test.log
	echo 'stop begin' >> /tmp/test.log
	service_stop /usr/bin/ss-redir
	service_stop /usr/bin/ss-tunnel
	killall /usr/bin/ss-redir
	killall /usr/bin/ss-tunnel
    iptables -t nat -D PREROUTING -p tcp -m set --match-set gfwlist dst -j REDIRECT --to-port 1081
    iptables -t nat -D OUTPUT -p tcp -m set --match-set gfwlist dst -j REDIRECT --to-port 1081
    ipset flush gfwlist
	echo 'stop end' >> /tmp/test.log
	return 0
}
