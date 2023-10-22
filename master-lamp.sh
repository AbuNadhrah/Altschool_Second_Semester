#!/bin/bash

# 2 - Setup LAMP on master

set -e

###User Management segment
#Change here - this is running directly on the master, so I'll remove the checking

    # Create a user named altschool only on the master VM
    sudo useradd -m altschool
    # Set a password for the altschool user
    echo "altschool:password" | sudo chpasswd
    # Give the altschool user root privileges
    sudo usermod -aG sudo altschool


echo -e "\n\nUpdating Apt Packages and upgrading latest patches\n"

# Update packages
sudo apt-get update -y

# Install Apache
sudo apt-get install -y apache2

#Open the firewall just in case
echo -e "\n\nAdding firewall rule to Apache\n"
sudo ufw allow in "Apache"

sudo ufw status

# 3 - Clone Laravel from github
cd /var/www/html && git clone https://github.com/laravel/laravel.git

#composer for laravel
sudo apt-install curl
curl -sS getcomposer.org/installer | php

sudo mv composer.phar /usr/locl/bin/composer

composer --version

#change some env variables in the laravel .env
sudo sed -i 's/DB_DATABASE=laravel/DB_DATABASE=dudu/' /var/www/html/laravel/.env

sudo sed -i 's/DB_USERNAME=laravel/DB_USERNAME=dudu/' /var/www/html/laravel/.env

sudo sed -i 's/DB_DATABASE=/DB_DATABASE=duduCOM/' /var/www/html/laravel/.env

#Set permissions
echo -e "\n\nPermissions for /var/www/html/laravel\n"
sudo chown -R www-data:www-data /var/www/html/laravel
sudo chmod -R 775 /var/www/html/laravel
sudo chmod -R 775 /var/www/html/laravel/storage
sudo chmod -R 775 /var/www/html/laravel/bootstrap/cache
cd /var/www/html/laravel && cp .env.example .env

echo -e "\n\n Permissions have been set\n"

#Configure Apache

cat <<EOF > /etc/apache2/sites-available/laravel.conf
<VirtualHost *:80>
    ServerAdmin admin@example.com
    ServerName 192.168.56.106
    DocumentRoot /var/www/html/laravel/public

    <Directory /var/www/html/laravel>
    Options Indexes Multiviews FollowSymLinks
    AllowOverride All
    Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>

EOF

echo -e "\n\nEnabling Modules\n"
sudo a2enmod rewrite
sudo phpenmod mcrypt

sudo sed -i 's/DirectoryIndex index.html index.cgi index.pl index.xhtml index.htm/DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm/' /etc/apache2/mods-enabled/dir.conf


# Install MySQL and set root password
echo -e "\n\nInstalling MySQL\n"

sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'
sudo apt-get install -y mysql-server

#Configure MySql

echo "Creating MySQL user and database"
PASS=$2
if [ -z "$2" ]; then
    PASS='openssl rand -base64 8'
fi 

mysql -u root <<MYSQL_SCRIPT
    CREATE DATABASE $1;
    CREATE USER '$1'@'localhost' IDENTIFIED BY '$PASS';
    GRANT ALLPRIVILEGES ON $1.* TO '$1'@'localhost';
    FLUSH PRIVILEGES;
MYSQL_SCRIPT

# Install PHP and related modules
sudo apt-get install -y php libapache2-mod-php php-mysql

sudo sed -i 's/cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' /etc/php/8.2/apache2/php.ini

# Restart Apache
sudo service apache2 restart


