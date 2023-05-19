#!/bin/bash

MYSQL_ROOT_PASSWORD='Qwerty@123'

sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $MYSQL_ROOT_PASSWORD"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD"

sudo debconf-set-selections <<< 'nginx nginx/enable_apache select false'
sudo debconf-set-selections <<< 'apache2 apache2/enable_apache select true'

sudo apt update && sudo apt install -y apache2

sudo ufw allow OpenSSH
sudo ufw allow "Apache Full"
yes | sudo ufw enable

sudo apt update && sudo apt install -y mysql-server

sudo service mysql status

echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | sudo debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password $PHPMYADMIN_PASSWORD" | sudo debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/admin-pass password $MYSQL_ROOT_PASSWORD" | sudo debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password $PHPMYADMIN_PASSWORD" | sudo debconf-set-selections
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | sudo debconf-set-selections

sudo apt update && sudo apt install -y php libapache2-mod-php php-mysql

sudo apt update && sudo apt install -y phpmyadmin

sudo a2enconf phpmyadmin.conf

sudo service apache2 reload

echo "CREATE USER 'shubham'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';" | sudo mysql -u root -p"$MYSQL_ROOT_PASSWORD"
echo "GRANT ALL PRIVILEGES ON * . * TO 'shubham'@'localhost';" | sudo mysql -u root -p"$MYSQL_ROOT_PASSWORD"
echo "FLUSH PRIVILEGES;" | sudo mysql -u root -p"$MYSQL_ROOT_PASSWORD"

sudo apt install -y curl
curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo apt install -y nodejs

