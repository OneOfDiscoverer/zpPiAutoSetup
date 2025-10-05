#!/bin/sh

# Script to set up cron job for zapret auto-update
# Run this once to configure the system

# Make the script executable
chmod +x /opt/zapret/zapret_autoupdate.sh

# Create log file if it doesn't exist
touch /var/log/zapret_autoupdate.log

# Add cron job to run every 10 minutes
# Check if cron job already exists
if ! crontab -l 2>/dev/null | grep -q "/opt/zapret/zapret_autoupdate.sh"; then
    # Add the cron job
    (crontab -l 2>/dev/null; echo "*/10 * * * * /opt/zapret/zapret_autoupdate.sh") | crontab -
    echo "Cron job added successfully"
else
    echo "Cron job already exists"
fi

# Enable and start cron service on OpenWRT
/etc/init.d/cron enable
/etc/init.d/cron start

echo "Setup completed!"
echo "The script will check for updates every 10 minutes"
echo "Logs can be found at: /var/log/zapret_autoupdate.log"
echo ""
echo "To monitor the logs in real-time, use:"
echo "tail -f /var/log/zapret_autoupdate.log"
echo ""
echo "To manually run the update script:"
echo "/opt/zapret/zapret_autoupdate.sh"
echo ""
echo "To view current cron jobs:"
echo "crontab -l"
echo ""
echo "To remove the cron job:"
echo "crontab -l | grep -v '/opt/zapret/zapret_autoupdate.sh' | crontab -"
