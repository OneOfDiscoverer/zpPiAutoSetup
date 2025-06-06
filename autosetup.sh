#!/bin/sh

echo '\n' | ./install_easy.sh

./setpwm.sh

echo "# Put your custom commands here that should be executed once
# the system init finished. By default this file does nothing.

./opt/zapret/setpwm.sh
./opt/zapret/automacluci.sh
exit 0
" > /etc/rc.local

echo "
#!/bin/sh /etc/rc.common

# OpenWrt procd service script for Zapret Auto-Update
# Save as: /etc/init.d/zapret-auto-update

START=99
STOP=15

USE_PROCD=1

PROG="/opt/zapret/git-auto-update.sh"
CRON_ENTRY="*/10 * * * * /opt/zapret/git-auto-update.sh"

start_service() {
    # Check if the script exists
    [ -x "$PROG" ] || {
        echo "ERROR: $PROG not found or not executable"
        return 1
    }
    
    # Add cron job for every 10 minutes
    echo "Adding cron job for zapret auto-update..."
    
    # Remove existing cron job if it exists
    crontab -l 2>/dev/null | grep -v "/opt/zapret/git-auto-update.sh" | crontab -
    
    # Add new cron job
    (crontab -l 2>/dev/null; echo "$CRON_ENTRY") | crontab -
    
    echo "Zapret auto-update service started - checking every 10 minutes"
    
    # Run initial check
    procd_open_instance
    procd_set_param command "$PROG"
    procd_set_param respawn
    procd_close_instance
}

stop_service() {
    echo "Stopping zapret auto-update service..."
    
    # Remove cron job
    crontab -l 2>/dev/null | grep -v "/opt/zapret/git-auto-update.sh" | crontab -
    
    # Kill any running instances
    killall -q git-auto-update.sh
    
    echo "Zapret auto-update service stopped"
}

restart() {
    stop
    sleep 2
    start
}

status() {
    echo "Zapret Auto-Update Service Status:"
    echo "================================="
    
    # Check if cron job exists
    if crontab -l 2>/dev/null | grep -q "/opt/zapret/git-auto-update.sh"; then
        echo "✓ Cron job is active (runs every 10 minutes)"
    else
        echo "✗ Cron job is not active"
    fi
    
    # Check if script exists and is executable
    if [ -x "$PROG" ]; then
        echo "✓ Update script is present and executable"
    else
        echo "✗ Update script is missing or not executable"
    fi
    
    # Check if repository exists
    if [ -d "/opt/zapret/.git" ]; then
        echo "✓ Git repository is present"
    else
        echo "✗ Git repository is missing"
    fi
    
    # Show last log entries
    echo ""
    echo "Recent log entries:"
    echo "==================="
    if [ -f "/tmp/zapret-auto-update.log" ]; then
        tail -n 10 /tmp/zapret-auto-update.log
    else
        echo "No log file found"
    fi
}

# Custom commands
EXTRA_COMMANDS="status"
EXTRA_HELP="        status  Show service status and recent logs"
" > /etc/init.d/zapret-auto-update
chmod +x /etc/init.d/zapret-auto-update

# Enable the service to start on boot
/etc/init.d/zapret-auto-update enable

# Start the service
/etc/init.d/zapret-auto-update start

./automacluci.sh
