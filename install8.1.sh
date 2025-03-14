#!/bin/bash

#PHP 8.1
# Get PostgreSQL username and password from user
echo "ISIKAN DATA USERNAME, PASS dan DATABASE"
read -p "Masukkan Username PostgreSQL : " username
read -p "Masukkan Password PostgreSQL : " password
read -p "Masukkan Database PostgreSQL : " database
echo

# Update and upgrade the system
echo "Updating and upgrading the system..."
apt update && apt upgrade -y

# Install PostgreSQL and switch to the postgres user
echo "Installing PostgreSQL..."
apt install postgresql -y

# Switch to postgres user and configure PostgreSQL
su - postgres <<EOF
psql -c "CREATE USER $username WITH PASSWORD '$password';"
psql -c "\du"
psql -c "CREATE DATABASE $database ENCODING 'UTF8' TEMPLATE template0 OWNER $username;"
psql -c "\l"
psql -c "\c $database"
psql -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $username;"
psql -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $username;"
EOF

# Exit postgres user
echo "PostgreSQL configuration completed."

# Install PHP, NGINX, and necessary extensions
echo "Installing PHP, NGINX and other necessary packages..."
apt install php-fpm php-pgsql php-mbstring php-xmlrpc php-soap php-gd php-xml php-intl php-zip php-curl php-cli php-opcache php-readline nginx unzip -y

# Download and extract Moodle
echo "Downloading Moodle..."
git clone git://git.moodle.org/moodle.git && rm -R /var/www/html/* && cp -R moodle/* /var/www/html

# Set proper permissions for Moodle directory
echo "Setting permissions for Moodle directory..."
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html
mkdir /var/www/moodledata
chown -R www-data:www-data /var/www/moodledata
chmod -R 770 /var/www/moodledata

# Update NGINX configuration
echo "Updating NGINX configuration..."
cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak
cat << 'EOF' > /etc/nginx/sites-available/default
server {
    listen 80;
    server_name yourdomain.com;
    client_max_body_size 100M;
    client_body_timeout 120s;

    root /var/www/html;
    index index.php;

    location / {
        try_files $uri $uri/ /index.php;
    }

    location ~ [^/]\.php(/|$) {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_index index.php;
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
        include fastcgi_params;
        fastcgi_param PATH_INFO $fastcgi_path_info;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }

    location ~* \.js$|\.css$|\.png$|\.jpg$|\.jpeg$|\.gif$|\.ico$|\.svg$|\.woff$|\.woff2$|\.ttf$|\.otf$|\.eot$|\.ttc$|\.jpe$ {
        expires max;
        log_not_found off;
    }
}
EOF

# Test and restart NGINX
echo "Testing and restarting NGINX..."
/sbin/nginx -t && systemctl restart nginx

# Update PHP configuration
echo "Updating PHP configuration..."
sed -i "s/max_execution_time = .*/max_execution_time = 300/" /etc/php/8.1/fpm/php.ini
sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/8.1/fpm/php.ini
sed -i "s/post_max_size = .*/post_max_size = 100M/" /etc/php/8.1/fpm/php.ini
sed -i "s/upload_max_filesize = .*/upload_max_filesize = 100M/" /etc/php/8.1/fpm/php.ini
#sed -i "s/max_input_vars = .*/max_input_vars = 5000/" /etc/php/8.1/fpm/php.ini
echo "max_input_vars = 5000" >> /etc/php/8.1/fpm/php.ini

# Restart PHP-FPM service
echo "Restarting PHP-FPM service..."
systemctl restart php8.1-fpm

# Check status of PHP-FPM
echo "Checking PHP-FPM status..."
systemctl status php8.1-fpm

# Get the server's IP address
server_ip=$(hostname -I | awk '{print $1}')

# Display configuration details
echo "Moodle installation and configuration completed successfully!"
echo "Server IP address: http://$server_ip"
echo "PostgreSQL username: $username"
echo "PostgreSQL password: $password"
echo "PostgreSQL Datbase: $database"
