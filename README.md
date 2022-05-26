# Zabbix_Agent-Installer
This bash script to makes it easier and faster to deploy Zabbix Agents on Ubuntu.

# Testing
The script has only been tested on Ubuntu-20.04, but it should run on most Linux distributions with minor changes.

# Installation
1. Download "Zabbix_Agent-Installer.sh" or copy the raw text to a .sh file.
2. Run the following command to allow the file to be executed: "chmod +x Zabbix_Agent-Installer.sh"
3. Run the script with: ./Zabbix_Agent-Installer.sh

# Encryption support
The script only supports PSK encryption or no encryption at the moment.

# Files created by the script
The script creates /etc/zabbix/backup.conf which is used to restore the zabbix agent to default settings if the script is run again.

# Files deleted by the script
The script downloads the file: "zabbix-release_6.0-1+ubuntu20.04_all.deb" and deletes it after the installation is done.

# Permissions changes made by the script
If "remote scripts" is enabled in the script, the script automatically adds the 'zabbix' user to Sudoers, if the 'zabbix' user is already in: "/etc/sudoers", this step is skipped.
