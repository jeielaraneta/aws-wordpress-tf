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

# Add FORCE_SSL_LOGIN and FORCE_SSL_ADMIN lines to wp-config.php
echo -e "\ndefine('WP_HOME', 'https://${URL}');\ndefine('WP_SITEURL', 'https://${URL}' );" >> "${WP_CONFIG}"

# Get the salt and put them in the wp-config.php
SALT=$(curl -L https://api.wordpress.org/secret-key/1.1/salt/)
STRING='put your unique phrase here'
printf '%s\n' "g/$STRING/d" a "$SALT" . w | ed -s "${WP_CONFIG}"

# start httpd service
sudo systemctl enable mariadb httpd
sudo systemctl start mariadb httpd