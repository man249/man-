#!/bin/bash

# Function to execute commands on the remote machine
execute_remote_command() {
    ssh remoteadmin@"$1"-mgmt "$2"
}

# Function to update system configuration
update_system_config() {
    # Change system name
    execute_remote_command "$1" "sudo hostnamectl set-hostname $2"
    execute_remote_command "$1" "sudo sed -i 's/^127.0.1.1.*$/$3 $2/' /etc/hosts"
    
    # Change IP address on LAN
    execute_remote_command "$1" "sudo sed -i 's/^address .*$/address $4/' /etc/netplan/01-netcfg.yaml"
    execute_remote_command "$1" "sudo netplan apply"
    
    # Add machine to /etc/hosts
    execute_remote_command "$1" "echo '$5 $2' | sudo tee -a /etc/hosts > /dev/null"
}

# Update target1-mgmt
update_system_config "target1" "loghost" "172.16.1.10" "3" "172.16.1.4 webhost"

# Install and configure ufw on target1-mgmt
execute_remote_command "target1" "sudo apt-get update && sudo apt-get install -y ufw"
execute_remote_command "target1" "sudo ufw allow from 172.16.1.0/24 to any port 514/udp"

# Configure rsyslog on target1-mgmt
execute_remote_command "target1" "sudo sed -i '/^#module(load=\"imudp\"/s/^#//; /^#input(type=\"imudp\"/s/^#//)' /etc/rsyslog.conf"
execute_remote_command "target1" "sudo systemctl restart rsyslog"

# Update target2-mgmt
update_system_config "target2" "webhost" "172.16.1.11" "4" "172.16.1.3 loghost"

# Install and configure ufw and apache2 on target2-mgmt
execute_remote_command "target2" "sudo apt-get update && sudo apt-get install -y ufw apache2"
execute_remote_command "target2" "sudo ufw allow 80/tcp"

# Configure rsyslog on target2-mgmt
execute_remote_command "target2" "echo '*.* @loghost' | sudo tee -a /etc/rsyslog.conf > /dev/null"
execute_remote_command "target2" "sudo systemctl restart rsyslog"

# Update /etc/hosts on NMS
echo '172.16.1.10 loghost' | sudo tee -a /etc/hosts > /dev/null
echo '172.16.1.11 webhost' | sudo tee -a /etc/hosts > /dev/null

# Verify Apache on NMS
firefox http://webhost &

# Verify logs on NMS
ssh remoteadmin@loghost grep webhost /var/log/syslog

# Inform user
echo "Configuration update succeeded."
