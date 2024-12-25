#!/bin/bash

# Update and upgrade the system
echo "Updating and upgrading the system..."
apt update && apt upgrade -y

# Install PostgreSQL and switch to the postgres user
echo "Installing PostgreSQL..."
apt install postgresql -y

# Switch to postgres user and configure PostgreSQL
su - postgres <<'EOF'
psql -c "CREATE USER admin WITH PASSWORD 'Admin123!@#';"
psql -c "\du"
psql -c "CREATE DATABASE moodle ENCODING 'UTF8' TEMPLATE template0 OWNER admin;"
psql -c "\l"
psql -c "\c moodle"
psql -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin;"
psql -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO admin;"
EOF

# Exit postgres user
echo "PostgreSQL configuration completed."

# Install PHP, NGINX, and necessary extensions
echo "Installing PHP, NGINX and other necessary packages..."
apt install php-fpm php-pgsql php-mbstring php-xmlrpc php-soap php-gd php-xml php-intl php-zip php-curl php-cli php-opcache php-readline nginx unzip -y

# Download and extract Moodle
echo "Downloading Moodle..."
wget https://download.moodle.org/download.php/direct/stable405/moodle-latest-405.zip -O moodle.zip && unzip moodle.zip && rm -R /var/www/html/* && cp -R moodle/* /var/www/html

# Set proper permissions for Moodle directory
echo "Setting permissions for Moodle directory..."
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html
mkdir /var/www/moodledata
chown -R www-data:www-data /var/www/moodledata
chmod -R 770 /var/www/moodledata

# Update NGINX configuration
echo "Updating NGINX configuration..."
cat << 'EOF' > /etc/nginx/sites-available/default
server {
    listen 80;
    server_name yourdomain.com;
    client_max_body_size 10M;
    client_body_timeout 120s;

    root /var/www/html;
    index index.php;

    location / {
        try_files $uri /index.php;
    }

    location ~ [^/]\.php(/|$) {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_index index.php;
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
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
sed -i "s/max_execution_time = .*/max_execution_time = 300/" /etc/php/8.2/fpm/php.ini
sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/8.2/fpm/php.ini
sed -i "s/post_max_size = .*/post_max_size = 100M/" /etc/php/8.2/fpm/php.ini
sed -i "s/upload_max_filesize = .*/upload_max_filesize = 100M/" /etc/php/8.2/fpm/php.ini
sed -i "s/max_input_vars = .*/max_input_vars = 5000/" /etc/php/8.2/fpm/php.ini

# Restart PHP-FPM service
echo "Restarting PHP-FPM service..."
systemctl restart php8.2-fpm

# Check status of PHP-FPM
echo "Checking PHP-FPM status..."
systemctl status php8.2-fpm

echo "Moodle installation and configuration completed successfully!"
