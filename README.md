# System Monitoring with Telegram Alerts

This bash script monitors system resources like CPU, RAM, Disk usage, SSH logins, and SFTP logins on a Unix-like system. It sends alerts to a specified Telegram chat when thresholds are exceeded or new logins are detected. Additionally, the script fetches the country information of SSH login IP addresses.

## Features

- **Monitor CPU, RAM, Disk, and Temperature Usage**: Sends alerts when usage exceeds specified thresholds.
- **SSH and SFTP Login Monitoring**: Detects and notifies new logins, showing IP address and country of origin.
- **Telegram Notifications**: Sends alerts to a specified Telegram group or user.
- **Customizable Check Intervals**: Allows different intervals for monitoring urgent (CPU, RAM) and less frequent checks (Disk, Temperature).
- **Country Lookup for SSH Logins**: Automatically fetches country information from IP addresses.

## Requirements

- A Telegram Bot (see below on how to set it up).
- `curl` installed on your server.
- A Unix-like system (Linux, macOS, etc.).

## Installation

1. **Clone the Repository**:

   ```bash
   git clone https://github.com/Sincan2/system-monitoring-telegram.git
   cd system-monitoring-telegram
   ```

2. **Make the Script Executable**:

   ```bash
   chmod +x mon.sh
   ```

3. **Edit the Script**:

   Open the `mon.sh` file and update the following lines with your own Telegram bot token and chat ID:

   ```bash
   BOT_TOKEN="your-telegram-bot-token"
   GROUP_ID="your-telegram-chat-id"
   ```

   You can obtain a bot token by creating a new bot via [BotFather](https://core.telegram.org/bots#botfather). For the chat ID, you can send a message to the bot and use this [method](https://stackoverflow.com/questions/32423837/telegram-bot-how-to-get-a-group-chat-id) to find your chat ID.

## Usage

You can customize the script to monitor specific system metrics. Here's how to use the script:

### Example Commands:

1. **Monitor CPU and RAM**:
   ```bash
   ./mon.sh --CPU 80 --RAM 70
   ```

2. **Monitor CPU, RAM, and Disk**:
   ```bash
   ./mon.sh --CPU 80 --RAM 70 --DISK 90 --DISK-TARGET /
   ```

3. **Monitor SSH and SFTP Logins**:
   ```bash
   ./mon.sh --SSH-LOGIN --SFTP-MONITOR
   ```

### Script Options:

| Option              | Description |
|---------------------|-------------|
| `--CPU <CPU_%>`     | Set CPU usage threshold (in percentage). |
| `--RAM <RAM_%>`     | Set RAM usage threshold (in percentage). |
| `--DISK <DISK_%>`   | Set Disk usage threshold (in percentage). |
| `--DISK-TARGET <path>` | Set Disk mount point to monitor (must be used with `--DISK`). |
| `--TEMP <TEMP_°C>`  | Set CPU temperature threshold (in Celsius). |
| `--SSH-LOGIN`       | Monitor SSH logins and send alerts. |
| `--SFTP-MONITOR`    | Monitor SFTP logins and send alerts. |
| `--REBOOT`          | Send alert if the server has been rebooted. |
| `-h`, `--help`      | Show help message. |

## Running Automatically on System Boot

To ensure the script runs at system startup, you can add it to your crontab:

1. Open the crontab file:

   ```bash
   crontab -e
   ```

2. Add the following line to execute the script on boot:

   ```bash
   @reboot /path/to/mon.sh --CPU 80 --RAM 70 --DISK 90 --SSH-LOGIN --SFTP-MONITOR
   ```

3. Save and exit. Now, the script will run every time the server reboots.

## Scheduling Regular Monitoring

To run the script at regular intervals (e.g., every 30 minutes), add the following line to your crontab:

```bash
*/30 * * * * /path/to/mon.sh --CPU 80 --RAM 70 --DISK 90 --SSH-LOGIN --SFTP-MONITOR
```

This will run the script every 30 minutes.

## Example Telegram Notification

When the script detects a new SSH login, you will receive a notification like this in your Telegram group:

```
From Host: your.server.com
⚠️  New SSH login from user: root at IP: 192.168.1.100 [Country: US]
```

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contributing

Feel free to submit pull requests to improve the script or add new features.

---

### Catatan Penting untuk Dokumentasi:

- **Bot Token dan Chat ID**: Ganti `BOT_TOKEN` dan `GROUP_ID` dalam file script `mon.sh` dengan token bot Telegram Anda dan ID grup atau chat Anda.
- **Perintah Crontab**: Pastikan mengganti `/path/to/mon.sh` dengan path lengkap ke lokasi di mana Anda menyimpan skrip.

Setelah mengikuti langkah-langkah ini, Anda dapat memantau server Anda dan menerima notifikasi ke Telegram secara otomatis.

