#!/bin/ash

# OpenWrt LuCI script to get MAC from first device on br-lan and set it to eth0
# Usage: ./set_eth0_mac_luci.sh

LOG_TAG="MAC_SCRIPT"
BRIDGE_INTERFACE="br-lan"
TARGET_INTERFACE="eth0"

# Function to log messages
log_msg() {
    logger -t "$LOG_TAG" "$1"
    echo "$(date): $1"
}

# Function to get first connected device MAC from br-lan
get_first_device_mac() {
    # Get bridge MAC table, exclude bridge itself and extract MAC addresses
    local mac_list=$(brctl showmacs "$BRIDGE_INTERFACE" 2>/dev/null | \
                     awk 'NR>1 && $3=="no" {print $2}' | \
                     grep -v "^00:00:00:00:00:00$" | \
                     head -1)
    
    if [ -z "$mac_list" ]; then
        # Alternative method using ARP table
        mac_list=$(ip neigh show dev "$BRIDGE_INTERFACE" | \
                   awk '$NF=="REACHABLE" || $NF=="STALE" {print $5}' | \
                   head -1)
    fi
    
    echo "$mac_list"
}

# Function to validate MAC address format
is_valid_mac() {
    local mac="$1"
    echo "$mac" | grep -qE '^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$'
}

# Function to set MAC address using UCI
set_interface_mac_uci() {
    local interface="$1"
    local new_mac="$2"
    
    # Find the UCI section for the interface
    local uci_section=""
    
    # Check if it's a device (newer OpenWrt versions)
    if uci show network | grep -q "device.*name='$interface'"; then
        uci_section=$(uci show network | grep "device.*name='$interface'" | cut -d'.' -f1-2)
        if [ -n "$uci_section" ]; then
            log_msg "Setting MAC for device $interface via UCI: $uci_section"
            uci set "$uci_section.macaddr=$new_mac"
        fi
    fi
    
    # Also check interface sections (for compatibility)
    local interface_sections=$(uci show network | grep "interface.*ifname.*$interface\|interface.*device.*$interface" | cut -d'.' -f1-2)
    for section in $interface_sections; do
        if [ -n "$section" ]; then
            log_msg "Setting MAC for interface section: $section"
            uci set "$section.macaddr=$new_mac"
        fi
    done
    
    # If no specific section found, try to set it as a device
    if [ -z "$uci_section" ] && [ -z "$interface_sections" ]; then
        log_msg "Creating device section for $interface"
        local device_name="device_$interface"
        uci set "network.$device_name=device"
        uci set "network.$device_name.name=$interface"
        uci set "network.$device_name.macaddr=$new_mac"
    fi
    
    # Commit changes
    uci commit network
    if [ $? -eq 0 ]; then
        log_msg "UCI configuration updated successfully"
        return 0
    else
        log_msg "ERROR: Failed to commit UCI changes"
        return 1
    fi
}

# Function to get current MAC of interface
get_current_mac() {
    local interface="$1"
    ip link show "$interface" 2>/dev/null | grep -o 'link/ether [0-9a-f:]*' | awk '{print $2}'
}

# Function to get MAC from UCI configuration
get_uci_mac() {
    local interface="$1"
    
    # Check device sections first
    local device_mac=$(uci show network | grep "device.*name='$interface'" | head -1 | cut -d'.' -f1-2)
    if [ -n "$device_mac" ]; then
        uci get "$device_mac.macaddr" 2>/dev/null
        return
    fi
    
    # Check interface sections
    local interface_sections=$(uci show network | grep "interface.*ifname.*$interface\|interface.*device.*$interface" | cut -d'.' -f1-2)
    for section in $interface_sections; do
        local mac=$(uci get "$section.macaddr" 2>/dev/null)
        if [ -n "$mac" ]; then
            echo "$mac"
            return
        fi
    done
}

# Function to reload network configuration
reload_network() {
    log_msg "Reloading network configuration..."
    
    # Use ubus to reload network
    if command -v ubus >/dev/null 2>&1; then
        ubus call network reload
        if [ $? -eq 0 ]; then
            log_msg "Network reloaded via ubus"
        else
            log_msg "ubus reload failed, trying service restart"
            /etc/init.d/network reload
        fi
    else
        log_msg "ubus not available, using service reload"
        /etc/init.d/network reload
    fi
    
    # Wait a moment for the changes to take effect
    sleep 3
}

# Main execution
main() {
    log_msg "Starting LuCI MAC address script for $TARGET_INTERFACE"
    
    # Check if UCI is available
    if ! command -v uci >/dev/null 2>&1; then
        log_msg "ERROR: UCI command not found. This script requires OpenWrt with UCI."
        exit 1
    fi
    
    # Check if target interface exists
    if ! ip link show "$TARGET_INTERFACE" >/dev/null 2>&1; then
        log_msg "ERROR: Interface $TARGET_INTERFACE does not exist"
        exit 1
    fi
    
    # Check if bridge exists
    if ! brctl show "$BRIDGE_INTERFACE" >/dev/null 2>&1; then
        log_msg "ERROR: Bridge $BRIDGE_INTERFACE does not exist"
        exit 1
    fi
    
    # Get current MAC of target interface
    current_mac=$(get_current_mac "$TARGET_INTERFACE")
    current_uci_mac=$(get_uci_mac "$TARGET_INTERFACE")
    log_msg "Current MAC of $TARGET_INTERFACE: $current_mac"
    log_msg "Current UCI MAC setting: $current_uci_mac"
    
    # Get MAC from first device on bridge
    log_msg "Searching for connected devices on $BRIDGE_INTERFACE..."
    target_mac=$(get_first_device_mac)
    
    if [ -z "$target_mac" ]; then
        log_msg "WARNING: No connected devices found on $BRIDGE_INTERFACE"
        log_msg "Waiting 10 seconds and retrying..."
        sleep 10
        target_mac=$(get_first_device_mac)
    fi
    
    if [ -z "$target_mac" ]; then
        log_msg "ERROR: No MAC address found from connected devices"
        exit 1
    fi
    
    # Validate MAC format
    if ! is_valid_mac "$target_mac"; then
        log_msg "ERROR: Invalid MAC address format: $target_mac"
        exit 1
    fi
    
    log_msg "Found device MAC: $target_mac"
    
    # Check if MAC is already set in UCI
    if [ "$current_uci_mac" = "$target_mac" ]; then
        log_msg "INFO: MAC address is already set in UCI configuration to $target_mac"
        # Still check if the actual interface has the right MAC
        if [ "$current_mac" = "$target_mac" ]; then
            log_msg "INFO: Interface MAC also matches. No changes needed."
            exit 0
        else
            log_msg "INFO: Interface MAC differs from UCI setting. Reloading network..."
            reload_network
            exit 0
        fi
    fi
    
    # Set the MAC address via UCI
    log_msg "Setting MAC address $target_mac to $TARGET_INTERFACE via UCI"
    if set_interface_mac_uci "$TARGET_INTERFACE" "$target_mac"; then
        # Reload network configuration
        reload_network
        
        # Verify the change
        new_mac=$(get_current_mac "$TARGET_INTERFACE")
        new_uci_mac=$(get_uci_mac "$TARGET_INTERFACE")
        
        log_msg "SUCCESS: UCI MAC setting: $new_uci_mac"
        log_msg "SUCCESS: Interface MAC is now: $new_mac"
        
        if [ "$new_mac" = "$target_mac" ]; then
            log_msg "Script completed successfully - MAC address applied"
	    reboot -f
        else
            log_msg "WARNING: UCI updated but interface MAC may need more time to update"
            log_msg "Current interface MAC: $new_mac, Expected: $target_mac"
        fi
    else
        log_msg "ERROR: Failed to set MAC address via UCI"
        exit 1
    fi
}

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root"
    exit 1
fi


# Execute main function

model=$(cat /tmp/sysinfo/model)

if [ "$model" != "OrangePi Zero3" ]; then
    main "$@"
fi
