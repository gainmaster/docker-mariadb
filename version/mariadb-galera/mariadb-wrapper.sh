#!/usr/bin/env bash

MARIADB_HOME=/var/lib/mysql
MARIADB_USER=mysql
MARIADB_ROOT_PASSWORD=${MARIADB_ROOT_PASSWORD:-password} #TODO: MAKE RANDOM

if [ -z "${CLUSTER_DOMAIN_NAME}" ]; then
    exit 1
fi

if [ ! -f ${MARIADB_HOME}/ibdata1 ]; then
    echo "POPULATE!"
    # Create MariaDB filesystem
    mysql_install_db \
        --user=${MARIADB_USER} \
        --basedir=/usr \
        --datadir=${MARIADB_HOME}

    chown -R ${MARIADB_USER}:${MARIADB_USER} ${MARIADB_HOME}
fi

#TODO: SECURE INSTALATION
if [ ! -d ${MARIADB_HOME}/test ]; then
    echo "SECURITY!"
    mysqld &
    sleep 10

    # Secure MariaDB instalation
    #
    #   Enter current password for root (enter for none):
    #   Set root password? [Y/n]
    #   New password:
    #   Re-enter new password:
    #   Remove anonymous users? [Y/n]
    #   Disallow root login remotely? [Y/n]
    #   Remove test database and access to it? [Y/n]
    #   Reload privilege tables now? [Y/n]
    mysql_secure_installation <<EOL

Y
$MARIADB_ROOT_PASSWORD
$MARIADB_ROOT_PASSWORD
Y
Y
Y
Y
EOL

    mysqld stop
    sleep 10
fi

ping -c 1 ${CLUSTER_DOMAIN_NAME}
if [ $? -eq 2 ]; then
    mysqld --wsrep-new-cluster
else
    mysqld --wsrep_cluster_address=gcomm://${CLUSTER_DOMAIN_NAME}
fi
