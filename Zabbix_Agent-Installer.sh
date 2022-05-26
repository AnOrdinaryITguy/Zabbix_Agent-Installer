#!/bin/bash
#Loading animation
echo "Zabbix Agent script is retrieving and installing the necessary packages..."  
while true; do echo -n .; sleep 1; done & trap 'kill $!' SIGTERM SIGKILL
#Adds the Zabbix repo and installs Zabbix agent
{
sudo wget https://repo.zabbix.com/zabbix/6.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.0-1+ubuntu20.04_all.deb
sudo dpkg -i zabbix-release_6.0-1+ubuntu20.04_all.deb
sudo apt-get update
sudo apt-get install zabbix-agent -y
} &> /dev/null

kill $!
echo ""
echo "Done"
#Creates a backup of the zabbix configuration and restores it if the script is run again
FILE=/etc/zabbix/backup.conf 
if test -f "$FILE"; then
    echo "Modified configuration file detected, restoring backup before installation..."
    cp /etc/zabbix/backup.conf /etc/zabbix/zabbix_agentd.conf
    echo "Done"
else
    echo "Backup configuration file missing, creating backup configuration file..."
    cp /etc/zabbix/zabbix_agentd.conf /etc/zabbix/backup.conf
    echo "Done"
fi

#Runs through the basic lines to configure Zabbix-agent
continue_exec () {
read -r -p "Do you want to use PSK encryption(yes or no)?" pskvalue
case $pskvalue in
      [yY][eE][sS]|[yY])
            sudo sh -c "openssl rand -hex 32 > /etc/zabbix/zabbix_agentd.psk"
            PSKkey=$(cat /etc/zabbix/zabbix_agentd.psk)
            hostname=$(cat /proc/sys/kernel/hostname)
            hostIP="$(hostname -I)"
            read -r -p "Choose a PSK identity: " PSKid
            sed -i -e "s|# TLSPSKIdentity=|TLSPSKIdentity=$PSKid|g" /etc/zabbix/zabbix_agentd.conf
            sed -i -e "s|# TLSConnect=unencrypted|TLSConnect=psk|g" /etc/zabbix/zabbix_agentd.conf
            sed -i -e "s|# TLSAccept=unencrypted|TLSAccept=psk|g" /etc/zabbix/zabbix_agentd.conf
            sed -i -e "s|# TLSPSKFile=|TLSPSKFile=/etc/zabbix/zabbix_agentd.psk|g" /etc/zabbix/zabbix_agentd.conf
            echo "PSK encryption successfully configured."
            read -r -p "Choose the IP address of the Zabbix monitor server: " Ipadd
            sed -i -e "s|Server=127.0.0.1|Server=$Ipadd|g" /etc/zabbix/zabbix_agentd.conf
            sed -i -e "s|ServerActive=127.0.0.1|ServerActive=$Ipadd|g" /etc/zabbix/zabbix_agentd.conf
            sed -i -e "s|# Hostname=|Hostname=$hostname|g" /etc/zabbix/zabbix_agentd.conf
            PSKstatus=true
            ;;
      [nN][oO]|[nN])
            hostname=$(cat /proc/sys/kernel/hostname)
            hostIP="$(hostname -I)"
            echo "PSK will not be configured"
            read -r -p "Choose the IP address of the Zabbix monitor server: " Ipadd
            sed -i -e "s|Server=127.0.0.1|Server=$Ipadd|g" /etc/zabbix/zabbix_agentd.conf
            sed -i -e "s|ServerActive=127.0.0.1|ServerActive=$Ipadd|g" /etc/zabbix/zabbix_agentd.conf
            sed -i -e "s|# Hostname=|Hostname=$hostname|g" /etc/zabbix/zabbix_agentd.conf
            ;;
      *)
            echo "Invalid input..."
            continue_exec
            ;;
esac
}
scripts_exec() {
read -r -p "Do you want to enable remote scripts on the configured agent?(yes or no)?" agentscript
case $agentscript in
      [yY][eE][sS]|[yY])
      sed -i -e "s|# EnableRemoteCommands=0|EnableRemoteCommands=1|g" /etc/zabbix/zabbix_agentd.conf
      #this portion creats a problem if the script is run multiple times. WORKING ON IT FIX THIS WHEN YOU HAVE TIME!!!
      zabbixadmin=$(tail -1 /etc/sudoers)
      if [ "$zabbixadmin" = "zabbix ALL=NOPASSWD: ALL" ];then
      echo "Zabbix already set as admin in SUDOERS, skipping step"
      Scriptstatus=true
      else
      echo "Adding Zabbix user to Sudoers"
      echo "zabbix ALL=NOPASSWD: ALL" >> /etc/sudoers
      fi
      ;;
      [nN][oO]|[nN])
      return
      ;;
      *)
      echo "Invalid input..."
      scripts_exec
      ;;
esac
}
conf_summary(){
      #Colored text:
      HEAD='\033[4;37m'
      GREEN='\033[0;32m'
      RED='\033[0;31m'
      NC='\033[0m' # No Color
      echo -e "$HEAD***Configuration Summary***$NC"
      echo "These settings have been configured for Zabbix agent."
      #Network settings
      echo -e "$HEAD**Host settings**$NC"
      echo "System hostname: "$hostname
      echo "System IP: "$hostIP
      #Zabbix server settings
      echo -e "$HEAD**Zabbix server settings**$NC"
      echo "Zabbix server IP: "$Ipadd
      if [ "$Scriptstatus" = true ];then
      echo -e "Remote scripts$GREEN enabled$NC"
      else
      echo -e "Remote scripts$RED disabled$NC"
      fi
      #Encryption
      echo -e "$HEAD**Encryption settings**$NC"
      if [ "$PSKstatus" = true ];then
      echo -e "PSK is$GREEN enabled$NC"
      echo "Your psk identity is: "$PSKid
      echo "Your PSK key is: "$PSKkey
      else
      echo -e "PSK is$RED disabled$NC"
      fi
}
continue_exec
scripts_exec
conf_summary

#restarts the agent and removes unnecessary files
{
sudo systemctl enable zabbix-agent.service
sudo systemctl stop zabbix-agent.service
sudo systemctl start zabbix-agent.service
sudo rm zabbix-release_6.0-1+ubuntu20.04_all.*
exit 0
} &> /dev/null
