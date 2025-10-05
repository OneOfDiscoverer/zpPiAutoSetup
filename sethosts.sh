#!/bin/sh
echo "127.0.0.1 localhost

::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters

104.244.42.2 api.twitter.com
104.244.42.66 api.twitter.com
104.244.42.130 api.twitter.com
104.244.42.194 api.twitter.com
57.144.244.34 instagram.com www.instagram.com
57.144.244.192 static.cdninstagram.com graph.instagram.com i.instagram.com api.instagram.com edge-c
57.144.244.1 fbcdn.net facebook.com fb.com fbsbx.com
31.13.66.63 scontent-hel3-1.cdninstagram.com scontent.cdninstagram.com
57.144.244.128 static.xx.fbcdn.net scontent.xx.fbcdn.net
31.13.67.20 scontent-hel3-1.xx.fbcdn.net

157.240.205.35 facebook.com www.facebook.com
157.240.205.35 m.facebook.com
157.240.9.174 instagram.com www.instagram.com
146.75.120.157 platform.twitter.com
104.244.42.2 api.twitter.com
104.244.42.66 api.twitter.com
104.244.42.130 api.twitter.com
104.244.42.194 api.twitter.com
104.244.42.2 api.x.com
104.244.42.66 api.x.com
104.244.42.130 api.x.com
104.244.42.194 api.x.com
172.66.0.227 t.co www.t.co twitter.com www.twitter.com mobile.twitter.com support.twitter.com syndication.twitter.com upload.twitter.com api.tweetdeck.com
162.159.140.229 t.co www.t.co
210.163.219.24 twimg.com
199.232.40.159 abs.twimg.com
104.244.42.2 api.twitter.com
104.18.37.127 pbs.twimg.com
104.18.36.146 video.twimg.com
104.244.43.131 abs-0.twimg.com
199.232.40.157 static.ads-twitter.com
31.13.72.53 scontent-arn2-1.cdninstagram.com scontent.cdninstagram.com static.cdninstagram.com
157.240.225.174 instagram.com www.instagram.com i.instagram.com
157.240.22.2 dgw.c10r.facebook.com
157.240.22.63 instagram.c10r.facebook.com
157.240.22.2 gateway.instagram.com
157.240.22.63 edge-chat.instagram.com" > /etc/hosts

service dnsmasq restart
