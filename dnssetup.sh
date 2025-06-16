opkg update
opkg install dnsmasq https-dns-proxy

/etc/init.d/log restart; /etc/init.d/dnsmasq restart; /etc/init.d/https-dns-proxy restart

pgrep -f -a dnsmasq; pgrep -f -a https-dns

uci show dhcp; uci show https-dns-proxy
