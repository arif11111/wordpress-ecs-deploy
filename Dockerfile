FROM wordpress:php7.4-apache

COPY plugins/ /var/www/html/wp-content/plugins/
COPY themes/ /var/www/html/wp-content/themes/
COPY uploads/ /var/www/html/wp-content/uploads/
