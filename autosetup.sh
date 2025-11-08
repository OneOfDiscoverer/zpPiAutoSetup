#!/bin/sh

echo '\n' | ./install_easy.sh

./setpwm.sh

echo "# Put your custom commands here that should be executed once
# the system init finished. By default this file does nothing.

./opt/zapret/setpwm.sh
./dnssetup.sh
./opt/zapret/automacluci.sh
exit 0
" > /etc/rc.local

./dnssetup.sh
./setup_zapret_autoupdate.sh
./sethosts.sh
./automacluci.sh
./setenabler.sh
