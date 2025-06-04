#!/bin/sh

echo '\n' | ./install_easy.sh

./setpwm.sh

echo "# Put your custom commands here that should be executed once
# the system init finished. By default this file does nothing.

./opt/zapret/setpwm.sh
./opt/zapret/automacluci.sh
exit 0
" > /etc/rc.local

echo "# Save as: /etc/systemd/system/zapret-auto-update.service
[Unit]
Description=Zapret Auto-Update Service
After=network.target

[Service]
Type=oneshot
User=root
ExecStart=/opt/zapret/git-auto-update.sh
StandardOutput=journal
StandardError=journal" > /etc/systemd/system/zapret-auto-update.service

echo "# Save as: /etc/systemd/system/zapret-auto-update.timer
[Unit]
Description=Run Zapret Auto-Update every 10 minutes
Requires=zapret-auto-update.service

[Timer]
OnBootSec=10min
OnUnitActiveSec=10min
Persistent=true

[Install]
WantedBy=timers.target" > /etc/systemd/system/zapret-auto-update.timer

service reload
service zapret-auto-update.service enable
service zapret-auto-update.service start
service zapret-auto-update.timer enable
service zapret-auto-update.timer start

./automacluci.sh
