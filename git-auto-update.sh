#!/bin/bash

# Git Auto-Update Script for Zapret
# This script checks for git updates every 10 minutes and runs autoinstall.sh if updates are found

REPO_DIR="/opt/zapret"
INSTALL_SCRIPT="/opt/zapret/autosetup.sh"
LOG_FILE="/var/log/zapret-auto-update.log"

# Function to log messages with timestamp
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to check and pull updates
check_and_update() {
    # Change to repository directory
    cd "$REPO_DIR" || {
        log_message "ERROR: Cannot change to directory $REPO_DIR"
        return 1
    }

    # Fetch latest changes from remote
    log_message "Fetching latest changes from remote repository..."
    git fetch origin || {
        log_message "ERROR: Failed to fetch from remote repository"
        return 1
    }

    # Check if local branch is behind remote
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse @{u})

    if [ "$LOCAL" = "$REMOTE" ]; then
        log_message "Repository is already up to date"
        return 0
    else
        log_message "Updates found. Pulling changes..."
        
        # Pull the changes
        git pull origin || {
            log_message "ERROR: Failed to pull changes"
            return 1
        }
        
        log_message "Successfully pulled updates"
        
        # Check if autoinstall script exists and is executable
        if [ -f "$INSTALL_SCRIPT" ]; then
            if [ -x "$INSTALL_SCRIPT" ]; then
                log_message "Executing autoinstall script..."
                "$INSTALL_SCRIPT" 2>&1 | tee -a "$LOG_FILE"
                if [ $? -eq 0 ]; then
                    log_message "Autoinstall script completed successfully"
                else
                    log_message "ERROR: Autoinstall script failed with exit code $?"
                fi
            else
                log_message "WARNING: Autoinstall script exists but is not executable"
                chmod +x "$INSTALL_SCRIPT"
                log_message "Made autoinstall script executable, running it..."
                "$INSTALL_SCRIPT" 2>&1 | tee -a "$LOG_FILE"
            fi
        else
            log_message "WARNING: Autoinstall script not found at $INSTALL_SCRIPT"
        fi
    fi
}

# Main execution
main() {
    log_message "Starting git auto-update check"
    
    # Check if repository directory exists
    if [ ! -d "$REPO_DIR" ]; then
        log_message "ERROR: Repository directory $REPO_DIR does not exist"
        exit 1
    fi
    
    # Check if it's a git repository
    if [ ! -d "$REPO_DIR/.git" ]; then
        log_message "ERROR: $REPO_DIR is not a git repository"
        exit 1
    fi
    
    # Run the update check
    check_and_update
    
    log_message "Git auto-update check completed"
}

# Run main function
main
