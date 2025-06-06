#!/bin/sh

echo '\n' | ./install_easy.sh

./setpwm.sh

echo "# Put your custom commands here that should be executed once
# the system init finished. By default this file does nothing.

./opt/zapret/setpwm.sh
./opt/zapret/automacluci.sh
exit 0
" > /etc/rc.local

./automacluci.sh
