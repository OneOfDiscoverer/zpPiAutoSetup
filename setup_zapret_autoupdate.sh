#!/bin/sh

# Script to set up cron job for zapret auto-update
# Run this once to configure the system

# Create the update script
cat > /opt/zapret/zapret_autoupdate.sh << 'EOF'
#!/bin/sh

# Script: /opt/zapret/zapret_autoupdate.sh
# Purpose: Auto-pull git updates for zapret and run autosetup.sh if changes detected

ZAPRET_DIR="/opt/zapret"
LOG_FILE="/var/log/zapret_autoupdate.log"
LOCK_FILE="/var/run/zapret_autoupdate.lock"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Function to check if another instance is running
check_lock() {
    if [ -f "$LOCK_FILE" ]; then
        PID=$(cat "$LOCK_FILE")
        if kill -0 "$PID" 2>/dev/null; then
            log_message "Another instance is already running (PID: $PID)"
            exit 1
        else
            log_message "Removing stale lock file"
            rm -f "$LOCK_FILE"
        fi
    fi
}

# Create lock file
create_lock() {
    echo $$ > "$LOCK_FILE"
}

# Remove lock file
remove_lock() {
    rm -f "$LOCK_FILE"
}

# Trap to ensure lock file is removed on exit
trap remove_lock EXIT

# Main update function
update_zapret() {
    # Check lock
    check_lock
    create_lock
    
    log_message "Starting zapret update check"
    
    # Check if directory exists
    if [ ! -d "$ZAPRET_DIR" ]; then
        log_message "ERROR: Directory $ZAPRET_DIR does not exist"
        exit 1
    fi
    
    # Change to zapret directory
    cd "$ZAPRET_DIR" || {
        log_message "ERROR: Cannot change to directory $ZAPRET_DIR"
        exit 1
    }
    
    # Get current commit hash
    OLD_COMMIT=$(git rev-parse HEAD 2>/dev/null)
    
    if [ -z "$OLD_COMMIT" ]; then
        log_message "ERROR: Not a git repository or git not available"
        exit 1
    fi
    
    # Fetch updates
    log_message "Fetching updates from remote repository"
    git fetch origin 2>&1 | while read line; do
        log_message "GIT: $line"
    done
    
    # Check if there are updates
    NEW_COMMIT=$(git rev-parse origin/HEAD 2>/dev/null || git rev-parse origin/master 2>/dev/null)
    
    if [ "$OLD_COMMIT" = "$NEW_COMMIT" ]; then
        log_message "No updates available"
    else
        log_message "Updates found. Pulling changes..."
        
        # Pull updates
        git pull 2>&1 | while read line; do
            log_message "GIT: $line"
        done
        
        # Check if pull was successful
        if [ $? -eq 0 ]; then
            log_message "Git pull successful. Running autosetup.sh..."
            
            # Check if autosetup.sh exists and is executable
            if [ -x "./autosetup.sh" ]; then
                ./autosetup.sh 2>&1 | while read line; do
                    log_message "SETUP: $line"
                done
                
                if [ $? -eq 0 ]; then
                    log_message "autosetup.sh completed successfully"
                else
                    log_message "ERROR: autosetup.sh failed with exit code $?"
                fi
            else
                log_message "ERROR: autosetup.sh not found or not executable"
            fi
        else
            log_message "ERROR: Git pull failed"
        fi
    fi
    
    log_message "Update check completed"
}

# Run the update function
update_zapret
EOF

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
