#!/bin/sh
#
# SFS.it Maintenance Server Tools 
# BSD style KISS scripts
#
# DESTROY USER WITH PASSWORD PWD_MYSQL, AND DB FOR USER ON MYSQL
#
# Written by Agostino Zanutto (agostino@sfs.it) for SFS.it MST
#

# USAGE destriy-vhost.sh USER PWD_MYSQL 
BASESCRIPT="$(basename $0)"
SYNTAX="$BASESCRIPT USER PWD_MYSQL"

SETTINGS_FILE="/etc/SFSit_MST.conf.sh"
test -s "/root/SFSit_MST.conf.sh" && SETTINGS_FILE="/root/SFSit_MST.conf.sh"
if [ -s "$SETTINGS_FILE" ]; then
	VHOSTS_DIR="$(sh "$SETTINGS_FILE" VHOSTS_DIR)"
	MYSQL_ROOT_PWD="$(sh "$SETTINGS_FILE" MYSQL_ROOT_PWD)"
    APACHE_VERSION="$(sh "$SETTINGS_FILE" APACHE_VERSION)"
fi
PWD_SRC="$(pwd)"
cd "$(realpath "$(dirname $0)")"
exit_with_error(){
	test 'x' != "x$1" && echo "$1"
	cd "$PWD_SRC"
	exit 1
}

[ "x$1" = 'x' ] && exit_with_error "$SYNTAX : VHOST needed"

VHOST=$1
VHOST_ACCOUNTFILE="$VHOSTS_DIR/$VHOST/account.txt";
[ -s "$VHOST_ACCOUNTFILE" ] || exit_with_error "ERROR: CANNOT LOAD 'account.txt' FOR $VHOST"

if [ "$( uname )" = 'FreeBSD' ]; then
    APACHE_DIR="/usr/local/etc/$APACHE_VERSION/Vhosts/$VHOST"
	[ -f "$APACHE_CONF.conf" ] && rm -f "$APACHE_CONF.conf"
	[ -f "$APACHE_CONF:ssl.conf" ] && rm -f "$APACHE_CONF:ssl.conf"
    NGINX_CONF="/usr/local/etc/nginx/Vhosts/$VHOST"
	[ -f "$NGINX_CONF.conf" ] && rm -f "$NGINX_CONF.conf"
	[ -f "$NGINX_CONF:ssl.conf" ] && rm -f "$NGINX_CONF:ssl.conf"
	service $APACHE_VERSION restart || exit_with_error "ERROR: restating $APACHE_VERSION"
elif [ "$( uname )" = 'Linux' ]; then
        VHOST_CONFIG_DIR='/etc/apache2/sites-available'
        VHOST_CONFIG_ENABLED_DIR='/etc/apache2/sites-enabled'
	rm -f "$VHOST_CONFIG_DIR/$VHOST" || exit_with_error "ERROR: WHILE DESTROY APACHE VHOST"
	rm -f "$VHOST_CONFIG_ENABLED_DIR/$VHOST" || exit_with_error "ERROR: WHILE DESTROY APACHE VHOST"
	service apache2 restart
fi
	
cd "$PWD_SRC"
exit 0
