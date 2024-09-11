#!/bin/bash

# Configuration variables for check intervals
FAST_CHECK_INTERVAL=60  # 1 minute in seconds
SLOW_CHECK_INTERVAL=1800  # 30 minutes in seconds

# SSH and SFTP activity logs
SSH_ACTIVITY_LOGINS="/root/ssh_activity_logins.txt"
SFTP_ACTIVITY_LOGINS="/root/sftp_activity_logins.txt"
LAST_BOOT_TIME_FILE="/root/last_boot_time.txt"

# Excluded IPs for SSH/SFTP monitoring
SSH_ACTIVITY_EXCLUDED_IPS=()

# Telegram Lock State (prevents notifications when lock is active)
TELEGRAMM_LOCK_STATE="/home/config-sync/telegramm_lock.state"

# Default host name
HOST_NAME=$(hostname -f)  # Get the full hostname

# Telegram Bot Token and Group ID
BOT_TOKEN="your-telegram-bot-token"   # Replace with your actual bot token
GROUP_ID="your-telegram-chat-id"      # Replace with your actual chat ID

# Color Codes for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to send alerts to Telegram with 2-second delay
send_telegram_alert() {
    local message="$1"
    local host_info=$HOST_NAME  # Get hostname only once

    # Format the message to be more readable using Markdown
    local full_message="*From Host:* \`$host_info\`\n$message"

    echo -e "${CYAN}Sending Telegram alert after 2-second delay: $full_message${NC}"  # Debugging log

    # Add 2-second delay before sending the message
    sleep 2

    local response=$(curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
        -d chat_id="$GROUP_ID" \
        -d text="$full_message" \
        -d parse_mode="Markdown")

    echo -e "${GREEN}Telegram API response:${NC} $response"  # Print response for debugging

    if echo "$response" | grep -q '"ok":false'; then
        echo -e "${RED}Error sending message to Telegram.${NC}"
        return 1
    fi
}

# Function to get country from IP address using ipinfo.io API
get_country_from_ip() {
    local ip_address=$1
    local country=$(curl -s "https://ipinfo.io/$ip_address/country")
    echo "$country"
}

# SSH login monitoring
check_ssh_activity() {
    local current_logins=$(who | awk '{print $1, $5}')
    local last_logins=$(cat "$SSH_ACTIVITY_LOGINS" 2>/dev/null || touch "$SSH_ACTIVITY_LOGINS")

    echo "$current_logins" > "$SSH_ACTIVITY_LOGINS"

    while IFS= read -r current_login; do
        if ! grep -Fq "$current_login" <<< "$last_logins"; then
            local user=$(echo "$current_login" | awk '{print $1}')
            local ip=$(echo "$current_login" | awk '{print $2}' | tr -d '()')

            # Get country from IP address
            local country=$(get_country_from_ip "$ip")

            echo -e "${YELLOW}⚠️  New SSH login from $user ($ip) [Country: $country]${NC}"
            send_telegram_alert "⚠️  *New SSH login* from user: \`$user\` at IP: \`$ip\` [Country: $country]"
        fi
    done <<< "$current_logins"
}

# Help message for script usage
print_help() {
    echo ""
    echo "Usage: $0 [options]"
    echo "Monitors system resources and sends alerts via Telegram if specified thresholds are exceeded."
    echo ""
    echo "Options:"
    echo "  --NAME host_name              Specifies a custom identifier for the host being monitored."
    echo "  --CPU <CPU_%>                 Sets the CPU usage percentage threshold for generating an alert."
    echo "  --RAM <RAM_%>                 Sets the RAM usage percentage threshold for generating an alert."
    echo "  --DISK <DISK_%>               Sets the disk usage percentage threshold for generating an alert."
    echo "  --DISK-TARGET <mount_point>   Specifies the mount point to monitor for disk usage. Must be used with --DISK."
    echo "  --TEMP <TEMP_°C>              Sets the CPU temperature threshold for generating an alert (in Celsius)."
    echo "  --SSH-LOGIN                   Activates monitoring of SSH logins and sends alerts for logins from non-excluded IPs."
    echo "  --SFTP-MONITOR                Activates monitoring of SFTP sessions and sends alerts for new sessions from non-excluded IPs."
    echo "  --REBOOT                      Sends an alert if the server has been rebooted since the last script execution."
    echo "  -h, --help                    Displays this help message."
    echo ""
    echo "Example:"
    echo "  $0 --NAME MyServer --CPU 80 --RAM 70 --DISK 90 --SSH-LOGIN --SFTP-MONITOR"
    echo ""
}

# Argument parsing and threshold settings
parse_arguments() {
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --NAME)
                if [[ -z "$2" || "$2" == --* ]]; then
                    echo -e "${RED}Error: --NAME must be followed by a server name.${NC}"
                    exit 1
                fi
                HOST_NAME="$2"
                shift 2
                ;;
            --CPU|--RAM|--DISK|--TEMP)
                if [[ -z "$2" || "$2" == --* ]]; then
                    echo -e "${RED}Error: $1 must be followed by a threshold value.${NC}"
                    exit 1
                fi
                declare -n threshold_var="${1#--}_THRESHOLD"
                threshold_var="$2"
                shift 2
                ;;
            --DISK-TARGET)
                if [[ -z "$2" || "$2" == --* ]]; then
                    echo -e "${RED}Error: --DISK-TARGET must be followed by a mount point.${NC}"
                    exit 1
                fi
                DISK_TARGET="$2"
                shift 2
                ;;
            --SSH-LOGIN)
                SSH_LOGIN_MONITORING=1
                shift
                ;;
            --SFTP-MONITOR)
                SFTP_MONITORING=1
                shift
                ;;
            --REBOOT)
                REBOOT_MONITORING=1
                shift
                ;;
            -h|--help)
                print_help
                exit 0
                ;;
            *)
                echo -e "${RED}Unknown parameter passed: $1${NC}"
                exit 1
                ;;
        esac
    done
}

# Fast monitor resources (CPU, RAM, SSH, SFTP)
fast_monitor_resources() {
    while true; do
        [[ "$SSH_LOGIN_MONITORING" -eq 1 ]] && check_ssh_activity
        sleep "$FAST_CHECK_INTERVAL"
    done
}

# Main logic
if [ "$#" -eq 0 ]; then
    print_help
    exit 0
fi

parse_arguments "$@"

# Start monitoring resources in the background
fast_monitor_resources &
wait
