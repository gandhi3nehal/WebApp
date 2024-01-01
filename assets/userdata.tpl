#!/bin/bash
sudo apt update -y
sudo apt install nginx -y
sudo ufw allow 'Nginx HTTP'
echo "<h1>Hello World from nginx</h1>" > /var/www/html/index.html
