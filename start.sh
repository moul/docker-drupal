#!/bin/bash

echo "Starting SSHD"
/usr/sbin/sshd -D &

if [ ! -d /data/sites/default ]; then
    echo "Installing Drupal sites"
    cd /data; tar xzf /var/www/sites.tgz
fi
chown -R www-data:www-data /data/sites/
chmod -R a+w /data/sites/

if [ ! -f /data/mysql-root-pw.txt ]; then
    echo "Generating mysql root password"
    pwgen -c -n -1 12 > /data/mysql-root-pw.txt
fi

if [ ! -f /data/drupal-db-pw.txt ]; then
    echo "Generating Drupal DB password"
    pwgen -c -n -1 12 > /data/drupal-db-pw.txt
fi

DRUPAL_DB="drupal"
MYSQL_PASSWORD=$(cat /data/mysql-root-pw.txt)
DRUPAL_PASSWORD=$(cat /data/drupal-db-pw.txt)

MYSQL_STARTED=false
if [ ! -d /data/mysql ]; then
    echo "Installing Mysql tables"
    cd /data && tar xf /var/lib/mysql.tgz
    # Start mysql
    MYSQL_STARTED=true
    /usr/bin/mysqld_safe & 
    sleep 10s

    mysqladmin -u root password $MYSQL_PASSWORD 
    echo mysql root password: $MYSQL_PASSWORD
    echo drupal password: $DRUPAL_PASSWORD
    mysql -uroot -p$MYSQL_PASSWORD -e "CREATE DATABASE drupal; GRANT ALL PRIVILEGES ON drupal.* TO 'drupal'@'localhost' IDENTIFIED BY '$DRUPAL_PASSWORD'; FLUSH PRIVILEGES;"
fi

if [ ! -f /data/sites/default/settings.php ]; then
    echo "Installing Drupal"
    # Start mysql
    if [ "$MYSQL_STARTED" == "false" ]; then
	MYSQL_STARTED=true
	/usr/bin/mysqld_safe & 
	sleep 10s
    fi

    cd /var/www/
    drush site-install standard -y --account-name=admin --account-pass=admin --db-url="mysqli://drupal:${DRUPAL_PASSWORD}@localhost:3306/drupal"
fi

if [ "$MYSQL_STARTED" == "true" ]; then
    killall mysqld sleep 10s
fi

echo "Starting Supervisord"
supervisord -n
