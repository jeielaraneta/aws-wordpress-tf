#!/bin/bash

# sudo yum update -y
# sudo yum install -y httpd
# sudo systemctl start httpd
# sudo systemctl enable httpd
# sudo chown -R apache:apache /var
# sudo chmod -R 755 /var

# cd /var/www/html
# echo "<h1>Hello, World!</h1>" > index.html
# sudo chown -R apache:apache /var/www/html
# sudo chmod -R 755 /var/www/html

sudo yum update -y

dnf install wget php-mysqlnd httpd php-fpm php-mysqli mariadb105-server php-json php php-devel -y
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz

sudo systemctl start mariadb httpd

mysql -u root -p"root" <<EOF
CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${PASSWORD}';
CREATE DATABASE \`${DATABASE}\`;
GRANT ALL PRIVILEGES ON \`${DATABASE}\`.* TO "${DB_USER}"@"localhost";
FLUSH PRIVILEGES;
EXIT
EOF

cp wordpress/wp-config-sample.php wordpress/wp-config.php

# Add FORCE_SSL_LOGIN and FORCE_SSL_ADMIN lines to wp-config.php
echo -e "\ndefine('FORCE_SSL_LOGIN', true);\ndefine('FORCE_SSL_ADMIN', true);" >> "${WP_CONFIG}"
echo -e "\ndefine( 'WP_MEMORY_LIMIT', '3048M' );\ndefine('WP_HOME', 'https://dev.ccst.com.au');\ndefine( 'WP_SITEURL', 'https://dev.ccst.com.au' );" >> "${WP_CONFIG}"
echo -e 'if (strpos($_SERVER['HTTP_X_FORWARDED_PROTO'], 'https') !== false)\n     $_SERVER['HTTPS']='on';' >> "${WP_CONFIG}"

# Change the database values
sudo sed -i "s/define( 'DB_NAME', 'database_name_here' )/define( 'DB_NAME', '${DATABASE}' )/" "${WP_CONFIG}"
sudo sed -i "s/define( 'DB_USER', 'username_here' )/define( 'DB_USER', '${DB_USER}' )/" "${WP_CONFIG}"
sudo sed -i "s/define( 'DB_PASSWORD', 'password_here' )/define( 'DB_PASSWORD', '${PASSWORD}' )/" "${WP_CONFIG}"

# Get the salt and put them in the wp-config.php
SALT=$(curl -L https://api.wordpress.org/secret-key/1.1/salt/)
STRING='put your unique phrase here'
printf '%s\n' "g/$STRING/d" a "$SALT" . w | ed -s "${WP_CONFIG}"

#Disable SElinux
sudo sed -i "s/SELINUX=permissive/SELINUX=disabled/" "${SELINUX_CONF}"

# Allow Permalinks
sudo sed -i '/<Directory "\/var\/www\/html">/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' "${HTTP_CONF}"

# Install PHP graphics library
sudo dnf install php-gd -y
sudo dnf install -y php8.2-gd

# Move wordpress to the /var/www/html directory
cp -r wordpress/* /var/www/html/
sudo chown -R apache /var/www
sudo chgrp -R apache /var/www
sudo chmod 755 /var/www
find /var/www -type d -exec sudo chmod 755 {} \;
find /var/www -type f -exec sudo chmod 644 {} \;
sudo chown -R apache:apache /var/www/html
sudo chmod -R 755 /var/www/html

# Change file upload settings
sudo sed -i 's/upload_max_filesize = .*/upload_max_filesize = 3000M/' "${PHP_INI}"
sudo sed -i 's/post_max_size = .*/post_max_size = 3000M/' "${PHP_INI}"
sudo sed -i 's/memory_limit = .*/memory_limit = 3048M/' "${PHP_INI}"
sudo sed -i 's/max_execution_time = .*/max_execution_time = 600/' "${PHP_INI}"
sudo sed -i 's/max_file_uploads = .*/max_file_uploads = 30/' "${PHP_INI}"

# restart httpd service
sudo systemctl stop httpd
sudo systemctl start httpd
sudo systemctl enable httpd