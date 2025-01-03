#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <port> <domain>"
    exit 1
fi

DOMAIN=$1
PORT=$2

echo "Updating packages and installing required tools..."
sudo apt update

NGINX_CONF_PATH="/etc/nginx/sites-available/$DOMAIN"
NGINX_LINK_PATH="/etc/nginx/sites-enabled/$DOMAIN"

rm -rf "/etc/nginx/sites-enabled"
rm -rf "/etc/nginx/sites-available"
mkdir -p "/etc/nginx/sites-enabled"
mkdir -p "/etc/nginx/sites-available"

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo apt install -y nginx certbot python3-certbot-nginx

echo "Creating nginx configuration for domain $DOMAIN..."
sudo bash -c "cat > $NGINX_CONF_PATH" <<EOL
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://localhost:$PORT;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_read_timeout 86400;
    }
}
EOL

sudo ln -s $NGINX_CONF_PATH $NGINX_LINK_PATH
sudo nginx -t && sudo systemctl restart nginx

echo "Obtaining an SSL certificate for domain $DOMAIN..."
sudo certbot --nginx
