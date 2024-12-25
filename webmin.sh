#!/bin/bash

# Update package index
echo "Updating package index..."
sudo apt update

# Install dependencies
echo "Installing dependencies..."
sudo apt install -y software-properties-common apt-transport-https curl

# Add Webmin repository GPG key
echo "Adding Webmin GPG key..."
curl -fsSL https://packages.webmin.com/gpg.key | sudo tee /etc/apt/trusted.gpg.d/webmin.asc

# Add Webmin repository
echo "Adding Webmin repository..."
sudo add-apt-repository "deb http://packages.webmin.com/repository/webmin sarge contrib"

# Update package index again after adding the repository
echo "Updating package index..."
sudo apt update

# Install Webmin
echo "Installing Webmin..."
sudo apt install -y webmin

# Allow Webmin through the firewall (if UFW is active)
if sudo ufw status | grep -q 'active'; then
  echo "Allowing Webmin through the firewall..."
  sudo ufw allow 10000
fi

# Display server IP address
IP_ADDRESS=$(hostname -I | awk '{print $1}')
echo "Webmin installation complete!"
echo "You can access Webmin via https://$IP_ADDRESS:10000"
