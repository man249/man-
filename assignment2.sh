#!/bin/bash

print_message() {
    echo -e "\n==================== $1 ====================\n"
}

configure_network() {
    print_message "Configuring network..."
    if [ -e /etc/netplan/01-network-manager-all.yaml ]; then
        sudo tee /etc/netplan/01-network-manager-all.yaml > /dev/null <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
      addresses:
        - 192.168.16.21/24
      gateway4: 192.168.16.1
      nameservers:
        addresses: [192.168.16.1]
        search: [home.arpa, localdomain]
EOF
        sudo netplan apply
        sudo sed -i '/192.168.16.21/d' /etc/hosts
        echo "192.168.16.21 server1" | sudo tee -a /etc/hosts > /dev/null
    else
        echo "Error: Netplan configuration file not found!"
    fi
}
install_software() {
    print_message "Installing software and configuring firewall..."
    if sudo apt update; then
        sudo apt install -y openssh-server apache2 squid
        sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
        sudo systemctl restart ssh
        sudo sed -i 's/Listen 80/Listen 192.168.16.21:80/' /etc/apache2/ports.conf
        sudo sed -i 's/<VirtualHost \*:80>/<VirtualHost 192.168.16.21:80>/' /etc/apache2/sites-available/000-default.conf
        sudo sed -i 's/Listen 443/Listen 192.168.16.21:443/' /etc/apache2/ports.conf
        sudo sed -i 's/<VirtualHost default:443>/<VirtualHost 192.168.16.21:443>/' /etc/apache2/sites-available/default-ssl.conf
        sudo systemctl restart apache2
        sudo sed -i 's/http_port 3128/http_port 192.168.16.21:3128/' /etc/squid/squid.conf
        sudo systemctl restart squid
        sudo ufw enable
        sudo ufw allow 22/tcp
        sudo ufw allow 80/tcp
        sudo ufw allow 443/tcp
        sudo ufw allow 3128/tcp
    else
        echo "Error: Failed to update package repository."
    fi
}
create_users() {
    print_message "Creating user accounts..."
    users=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")
    for user in "${users[@]}"; do
        sudo useradd -m -s /bin/bash "$user"
        sudo mkdir -p /home/$user/.ssh
        sudo touch /home/$user/.ssh/authorized_keys
        sudo chown -R $user:$user /home/$user/.ssh
        case "$user" in
        "dennis")
            echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC7nkdglw3M5V+OnUhphEjqSNoRJX6WJKo7ytmGtoWiSrx5MCyj4glJ1XEyNk8FyfBLHmkK0N6PslbNsVnc6BwjZ7JG5uzbq7jVxVLpj1QxjZy5A1cf+exd8uEFOiPxln8J2r1uIvD7l5XgYHsh5n3xlwT6l7Xo1lbRVNoHf2iS8KntTfyX8YNz0GqLo7oTnvAtTPOdLqekDT5i5XUN5yvVhsKgpX0sH9j2J06ZZr/V3a8vQ1ZSBBj0b/RRUPQb9hFfZ+7pTFh9QXdXHhHzLPH6b+Bnxd7cTHkiKsxlZ+H+KfmGtBWZ8NSMnVsGsF+v7vFQ9wM+6ZLcfll9I/d student@generic-vm" >> /home/$user/.ssh/authorized_keys > /dev/null
            echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm" | sudo tee -a /home/$user/.ssh/authorized_keys > /dev/null
            ;;
        *)
            echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDOw8iw+p6bW3KBY3Ue/xoQzjht+wcqRyntbR9c8Ng6RaXTpcoo6ED2E/3W2BZM5ZCJ90CiRqsruU6cxGRRmgZZJElEp7dB1bZNBStpJ71PnvVvYzwdnaakaz73XDLipI9aSdtjpgGt1gBOdtKifjSfeeAWAok8TAKa5vE+tGsduWdKQyfZj1JOVjgJbq4PKbgQ0jREGeQL6ESMpUr3khPjg8c5czfA/FDeexVoBTXqpt0sxnVBTi1C/m50qUzbUNP4+9I6+9RNxWgCDo4sr+Dz5Sqhnc5/GW17FXMHWJPF5tEULZEUw7aQbtRolYPGkAt/kqKXN4Gm5n5ZxhHhOVBOfe6sGlfVR1hZdAt0sMsmxPL6lJliOoRnWkhZo3DtD8GWWURQy89QDub+iNAhFHvzE0E4Ix51PwmNRe0FkwThnWDH/C+uzLvjS1VrFv3GUHX7hECZsWiQuOEyeEXa2cHir1eLe/QUXQiXpZ97PBSiGK6/5G5yfTg8J5O7ddPMdWE" >> /home/$user/.ssh/authorized_keys > /dev/null
            ;;
        esac
    done
    sudo usermod -aG sudo dennis
}
main() {
    configure_network
    install_software
    create_users
    print_message "Script execution completed successfully!"
}
main
