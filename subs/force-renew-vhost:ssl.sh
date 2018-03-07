#!/bin/sh
#
# SFS.it Maintenance Server Tools 
# BSD style KISS scripts
#
# CREATE certbot letsencrypt VHOSTs entry for VHOST
#
# Written by Agostino Zanutto (agostino@sfs.it) for SFS.it MST
#

# USAGE create-vhost.sh VHOST OTHER_HTTPS_HOST OTHER_HTTPS_HOST OTHER_HTTTPS_HOST ...
BASESCRIPT="$(basename $0)"
SYNTAX="$BASESCRIPT VHOST OTHER_HTTPS_HOST OTHER_HTTPS_HOST OTHER_HTTPS_HOST OTHER_HTTTPS_HOST ..."

SETTINGS_FILE="/etc/SFSit_MST.conf.sh"
test -s "/root/SFSit_MST.conf.sh" && SETTINGS_FILE="/root/SFSit_MST.conf.sh"
if [ -s "$SETTINGS_FILE" ]; then
        HOSTNAME="$(sh "$SETTINGS_FILE" HOSTNAME)"
        test "x$HOSTNAME" = "x" && HOSTNAME=$(hostname)
        SERVER_IP="$(sh "$SETTINGS_FILE" SERVER_IP)"
        [ "x$SERVER_IP" = 'x' ] && SERVER_IP='127.0.0.1'
        WEBSERVER="$(sh "$SETTINGS_FILE" WEBSERVER)"
        [ "x$WEBSERVER" != 'xapache' -a  "x$WEBSERVER" != 'xnginx' -a "x$WEBSERVER" != 'xnginx+apache' ] && WEBSERVER='apache'
        APACHE_VERSION="$(sh "$SETTINGS_FILE" APACHE_VERSION)"
        [ "x$APACHE_VERSION" != 'xapache22' -a "x$APACHE_VERSION" != 'xapache24' ] && APACHE_VERSION='apache24'
        APACHE_HTTP="$(sh "$SETTINGS_FILE" APACHE_HTTP)"
        APACHE_HTTPS="$(sh "$SETTINGS_FILE" APACHE_HTTPS)"
        if [ "x$WEBSERVER" = 'xapache' ]; then
                [ "x$APACHE_HTTP" = 'x' ] && APACHE_HTTPS='80'
                [ "x$APACHE_HTTPS" = 'x' ] && APACHE_HTTPS='443'
        else
                [ "x$APACHE_HTTP" = 'x' ] && APACHE_HTTPS='8080'
                [ "x$APACHE_HTTPS" = 'x' ] && APACHE_HTTPS='8443'
        fi
        VHOSTS_DIR="$(sh "$SETTINGS_FILE" VHOSTS_DIR)"
        HTTPDOCS_DIR="$(sh "$SETTINGS_FILE" HTTPDOCS_DIR)"
        HTTPLOGS_DIR="$(sh "$SETTINGS_FILE" HTTPLOGS_DIR)"
        DEVEL_DOMAIN="$(sh "$SETTINGS_FILE" DEVEL_DOMAIN)"
        WWW_GROUP="$(sh "$SETTINGS_FILE" WWW_GROUP)"
fi
PWD_SRC="$(pwd)"
cd $(dirname $0) 
exit_with_error(){
	test 'x' != "x$1" && echo "$1"
	cd "$PWD_SRC"
	exit 1
}

get_host(){
	echo $1 | sed -E 's/([^\.]*)\..*/\1/g'
}

get_domain(){
	echo $1 | sed -E 's/[^\.]*\.(.*)$/\1/g'
}

get_1st_level_domain(){
        if [ "x$1" != 'x' ]; then
                echo $1 | sed -E 's/([^\.]*\.)*(.*)$/\2/g'
        fi
}

change_1st_level_domain(){
        if [ "x$1" != 'x' -a "x$2" != 'x' ]; then
                echo $1 | sed -E "s/(([^\.]*\.)*)(.*)\$/\1$2/g"
        fi
}

[ "x$1" = 'x' ] && exit_with_error "$SYNTAX : 'VHOST' needed";
VHOST=$1

VHOST_ACCOUNTFILE="$VHOSTS_DIR/$VHOST/account.txt";
if [ -s "$VHOST_ACCOUNTFILE" ]; then
    CERTBOT_HOSTS=$(cat $VHOST_ACCOUNTFILE | grep 'CERTBOT_DOMAINS:' | sed 's/^CERTBOT_DOMAINS:\s*//' | sed 's/^[[:blank:]]*//g')
else
    CERTBOT_HOSTS=""
fi

DOMAIN="$( get_domain $VHOST )"
if [ "x$DEVEL_DOMAIN" != 'x' -a "x$DOMAIN" != "x$DEVEL_DOMAIN" ]; then
        VHOST_HOSTNAME="$(change_1st_level_domain $VHOST $DEVEL_DOMAIN)"
        echo "DEVELOPMENT DOMAIN change '$VHOST' in '$VHOST_HOSTNAME'"
	DOMAIN="$(get_domain $VHOST_HOSTNAME)"
else
        VHOST_HOSTNAME=$VHOST
fi
if [ "x$CERTBOT_HOSTS" = "x" ]; then
	CERTBOT_HOSTS="$VHOST_HOSTNAME"
fi
CERTBOT_PARAMS=" -d `echo $CERTBOT_HOSTS| sed 's/ / -d /g'`"
echo "CREATE SSL CERTIFICATES FOR $CERTBOT_HOSTS"
certbot certonly --force-renew --webroot -w "$VHOSTS_DIR/$VHOST/$HTTPDOCS_DIR" $CERTBOT_PARAMS || exit_with_error "ERROR: creating CERTIFICATES FOR '$VHOST'"
cd "$PWD_SRC"
service apache restart
service nginx restart
exit 0
