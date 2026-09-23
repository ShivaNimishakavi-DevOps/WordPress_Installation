#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Create a directory named "wordpress"
mkdir -p wordpress
cd wordpress

# Update system packages
sudo apt-get update
sudo apt-get upgrade -y

# Install Apache2
sudo apt-get install -y apache2

# Start and enable Apache2 service
sudo systemctl start apache2
sudo systemctl enable apache2

echo "Apache2 installed and started successfully!"

# Install PHP 8 and extensions
sudo apt install -y php php-{common,mysql,xml,xmlrpc,curl,gd,imagick,cli,dev,imap,mbstring,opcache,soap,zip,intl}

# Show PHP version
php -v

# Install MariaDB
sudo apt install -y mariadb-server mariadb-client

# Enable and start MariaDB
sudo systemctl enable --now mariadb

# Ensure script runs as root/sudo
[ "$EUID" -ne 0 ] && { echo "Please run this script with sudo or as root."; exit 1; }

# Run MySQL secure installation
sudo mysql_secure_installation

echo "MySQL secure installation completed successfully!"

# Collect MySQL details
read -s -p "Enter MySQL root password: " root_password && echo
read -p "Enter MySQL username: " username
read -s -p "Enter MySQL user password for '$username': " user_password && echo
read -p "Enter MySQL database name: " database_name

# Prepare MySQL commands
mysql_commands=$(cat <<EOF
CREATE USER IF NOT EXISTS '$username'@'localhost' IDENTIFIED BY '$user_password';
CREATE DATABASE IF NOT EXISTS \`$database_name\`;
GRANT ALL PRIVILEGES ON \`$database_name\`.* TO '$username'@'localhost';
FLUSH PRIVILEGES;
EXIT
EOF
)

# Execute MySQL commands
if echo "$mysql_commands" | mysql -u root -p"$root_password"; then
  echo "Database and user created successfully!"
else
  echo "Error: Failed to configure MySQL."
fi

# Install required tools
sudo apt-get install -y wget unzip

# Download and unzip WordPress
wget https://wordpress.org/latest.zip
sudo unzip latest.zip

# Define directories
destination_dir="/var/www/html/wordpress"
backup_dir="/var/www/html/old_wordpress_$(date +'%Y%m%d_%H%M%S')"

# Backup old installation if exists
if [ -d "$destination_dir" ]; then
  sudo mv "$destination_dir" "$backup_dir"
  echo "Existing WordPress moved to $backup_dir"
fi

# Move new WordPress files
sudo mv wordpress/ "$destination_dir"
echo "New WordPress moved to $destination_dir"

# Clean up
sudo rm -f latest.zip

# Set ownership and secure permissions
sudo chown -R www-data:www-data "$destination_dir"
sudo find "$destination_dir" -type d -exec chmod 755 {} \;
sudo find "$destination_dir" -type f -exec chmod 644 {} \;

echo "WordPress installation completed successfully."

# Create Apache virtual host
sudo tee /etc/apache2/sites-available/wordpress.conf > /dev/null <<EOF
<VirtualHost *:80>
    ServerAdmin admin@example.com
    DocumentRoot /var/www/html/wordpress
    ServerName example.com
    ServerAlias www.example.com

    <Directory /var/www/html/wordpress/>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

# Enable site and rewrite module
sudo a2ensite wordpress.conf
sudo a2enmod rewrite
sudo a2dissite 000-default.conf

# Restart Apache
sudo systemctl restart apache2

echo "WordPress virtual host configured successfully!"
