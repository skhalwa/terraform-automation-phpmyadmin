#!/bin/bash

MYSQL_ROOT_PASSWORD='Qwerty@123'
PHPMYADMIN_PASSWORD='password123'

# Set MySQL root password
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $MYSQL_ROOT_PASSWORD"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD"

# Set Apache and Nginx configurations
sudo debconf-set-selections <<< 'nginx nginx/enable_apache select false'
sudo debconf-set-selections <<< 'apache2 apache2/enable_apache select true'

# Update package lists and install Apache2
sudo apt update && sudo apt install -y apache2
APACHE_INSTALL_STATUS=$?

# Check if Apache2 installation was successful
if [ $APACHE_INSTALL_STATUS -eq 0 ]; then
  echo "Apache2 installation successful."
else
  echo "Apache2 installation failed."
  exit 1
fi

# Configure firewall
sudo ufw allow OpenSSH
sudo ufw allow "Apache Full"
yes | sudo ufw enable

# Update package lists and install MySQL Server
sudo apt update && sudo apt install -y mysql-server
MYSQL_INSTALL_STATUS=$?

# Check if MySQL Server installation was successful
if [ $MYSQL_INSTALL_STATUS -eq 0 ]; then
  echo "MySQL Server installation successful."
else
  echo "MySQL Server installation failed."
  exit 1
fi

# Check MySQL service status
sudo service mysql status

# Configure PHPMyAdmin
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | sudo debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password $PHPMYADMIN_PASSWORD" | sudo debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/admin-pass password $MYSQL_ROOT_PASSWORD" | sudo debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password $PHPMYADMIN_PASSWORD" | sudo debconf-set-selections
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | sudo debconf-set-selections

# Update package lists and install PHP and PHPMyAdmin
sudo apt update && sudo apt install -y php libapache2-mod-php php-mysql phpmyadmin
PHPMYADMIN_INSTALL_STATUS=$?

# Check if PHP and PHPMyAdmin installation was successful
if [ $PHPMYADMIN_INSTALL_STATUS -eq 0 ]; then
  echo "PHP and PHPMyAdmin installation successful."
else
  echo "PHP and PHPMyAdmin installation failed."
  exit 1
fi

# Enable PHPMyAdmin configuration for Apache
sudo a2enconf phpmyadmin.conf

# Reload Apache service to apply changes
sudo service apache2 reload

# Create MySQL user and grant privileges
echo "CREATE USER 'shubham'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';" | sudo mysql -u root -p"$MYSQL_ROOT_PASSWORD"
echo "GRANT ALL PRIVILEGES ON * . * TO 'shubham'@'localhost';" | sudo mysql -u root -p"$MYSQL_ROOT_PASSWORD"
echo "FLUSH PRIVILEGES;" | sudo mysql -u root -p"$MYSQL_ROOT_PASSWORD"

# Install Curl and Node.js
sudo apt install -y curl
curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo apt install -y nodejs

# Check if Node.js installation was successful
if [ $? -eq 0 ]; then
  echo "Node.js installation successful."
else
  echo "Node.js installation failed."
  exit 1
fi

# All resources installed successfully
echo "All resources installed successfully."

# Wait for 2-3 minutes (adjust the duration as needed)
# echo "Waiting for 2-3 minutes..."
# sleep 180