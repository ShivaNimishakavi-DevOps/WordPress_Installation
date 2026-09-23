#!/bin/bash

sudo rm -r /wordpress

sudo apt-get remove --purge mariadb-server mariadb-client -y
sudo apt-get autoremove -y
sudo apt-get autoclean -y 

sudo apt-get remove --purge php php-cli php-fpm php-mysql -y
sudo apt-get purge php* -y 
sudo a2dismod php* -y 
sudo apt-get autoremove -y
sudo apt-get autoclean -y 

sudo apt-get remove --purge apache2 -y
sudo apt-get purge apache2 -y 
sudo apt-get autoremove -y 
sudo apt-get autoclean -y
