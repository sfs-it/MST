#!/bin/sh
#
# SFS.it Maintenance Server Tools 
# BSD style KISS scripts
#
# CREATE Apache Vhost config for VHOST
#
# Written by Agostino Zanutto (agostino@sfs.it) for SFS.it MST
#

# USAGE create-vhost.sh VHOST OTHER_HTTPS_HOST OTHER_HTTPS_HOST OTHER_HTTTPS_HOST ...
BASESCRIPT="$(basename $0)"
SYNTAX="$BASESCRIPT VHOST OTHER_HTTPS_HOST OTHER_HTTPS_HOST OTHER_HTTTPS_HOST ..."

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
[ "x$1" = 'x' ] && exit_with_error "$SYNTAX : 'VHOST' needed";
VHOST=$1

VHOST_ACCOUNTFILE="$VHOSTS_DIR/$VHOST/account.txt";
[ -s "$VHOST_ACCOUNTFILE" ] || exit_with_error "ERROR: CANNOT LOAD 'account.txt' FOR $VHOST"
USER="$(cat $VHOST_ACCOUNTFILE | grep 'USER:' | sed 's/^USER:\s*//' | sed 's/^[[:blank:]]*//g')"
ADMIN_EMAIL="$(cat $VHOST_ACCOUNTFILE | grep 'ADMIN_EMAIL:' | sed 's/^ADMIN_EMAIL:\s*//' | sed 's/^[[:blank:]]*//g')"
VHOST_ONDOMAIN="$(echo $VHOST | sed -E 's/(\.[^\.]*)$//' | sed 's/^[[:blank:]]*//g')"

get_host(){
	if [ "x$1" != 'x' ]; then
		echo $1 | sed -E 's/([^\.]*)\..*$/\1/g'
	fi
}

get_domain(){
	if [ "x$1" != 'x' ]; then
		echo $1 | sed -E 's/[^\.]*\.(.*)$/\1/g'
	fi
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

SERVER_ALIASES=""
VHOST_HOSTNAME_ALIASES=""
add_aliases(){
	VHOST_ALIAS="$(echo $1 | sed 's/^[[:blank:]]*//g' | sed 's/[[:blank:]]*$//g')"
	if [ "x$VHOST_ALIAS" != "x" -a "x$VHOST_ALIAS" != "x$VHOST_HOSTNAME" ]; then
		PRESENCE_CHECK=$(printf "$SERVER_ALIASES" | grep "ServerAlias $VHOST_ALIAS")
		if [ "x$PRESENCE_CHECK" = "x" ]; then
			HOST_ALIAS="$(get_host $VHOST_ALIAS)"
			if [ "x$VHOST_ALIAS" != "x" ]; then
				SERVER_ALIASES="$SERVER_ALIASES\tServerAlias $VHOST_ALIAS\n"
				VHOST_HOSTNAME_ALIASES="$VHOST_HOSTNAME_ALIASES $VHOST_ALIAS"
				echo "ADD HOSTNAME '$VHOST_ALIAS' to Server Aliases"
				if [ ${#VHOST_ALIAS} -gt 4 -a "x$HOST_ALIAS" = 'xwww' ]; then
					ALIAS_DOMAIN="$(get_domain $VHOST_ALIAS)"
					PRESENCE_CHECK=$(printf "$SERVER_ALIASES" | grep "ServerAlias $ALIAS_DOMAIN")
					if [ "x$ALIAS_DOMAIN" != "x" -a "x$PRESENCE_CHECK" = "x" ]; then
						SERVER_ALIASES="$SERVER_ALIASES\tServerAlias $ALIAS_DOMAIN\n"
						VHOST_HOSTNAME_ALIASES="$VHOST_HOSTNAME_ALIASES $ALIAS_DOMAIN"
						echo "ADD DOMAIN '$ALIAS_DOMAIN' to Server Aliases"
					fi
				fi
			fi
		fi
	fi
}

[ "x$(get_1st_level_domain $VHOST)" = 'local' ] || \
	add_aliases "$(change_1st_level_domain $VHOST 'local')"
DOMAIN="$(get_domain $VHOST)"
if [ "x$DEVEL_DOMAIN" != 'x' -a "x$DOMAIN" != "x$DEVEL_DOMAIN" ]; then
	ALIAS_DEVEL_DOMAIN="$(change_1st_level_domain $VHOST $DEVEL_DOMAIN)"
	echo "DEVELOPMENT DOMAIN add '$VHOST' in '$ALIAS_DEVEL_DOMAIN'"
	add_aliases "$ALIAS_DEVEL_DOMAIN"
	DOMAIN="$(get_domain $VHOST_HOSTNAME)"
fi
VHOST_HOSTNAME=$VHOST
HOST="$(get_host $VHOST)"
if [ "x$(echo -n $DOMAIN | sed 's/^[[:blank:]]*//g' | sed 's/[[:blank:]]*$//g' )" != "x" -a \( "x$HOST" = "xwww" \) ]; then
	SERVER_ALIASES="$SERVER_ALIASES\tServerAlias $DOMAIN\n"
	VHOST_HOSTNAME_ALIASES="$VHOST_HOSTNAME_ALIASES $DOMAIN"
	echo "ADD DOMAIN '$DOMAIN' to Server Aliases"
fi
	
while [ "x$2" != "x" ]; do
	add_aliases $2
	shift
done
SERVER_ALIASES="$(printf "$SERVER_ALIASES" | tr '\n' '\r')"

nginx_template(){
	 cat "../templates/$WEBSERVER/nginx-vhost.conf.tpl" \
		| sed -E "s#\\{\\\$SERVER_IP\\}#$SERVER_IP#g" \
		| sed -E "s#\\{\\\$VHOST\\}#$VHOST#g" \
		| sed -E "s#\\{\\\$VHOST_HOSTNAME\\}#$VHOST_HOSTNAME#g" \
		| sed -E "s#\\{\\\$VHOST_HOSTNAME_ALIASES\\}#$VHOST_HOSTNAME_ALIASES#g" \
		| sed -E "s#\\{\\\$ADMIN_EMAIL\\}#$ADMIN_EMAIL#g" \
		| sed -E "s#\\{\\\$VHOSTS_DIR\\}#$VHOSTS_DIR#g" \
                | sed -E "s#\\{\\\$HTTPDOCS_DIR\\}#$HTTPDOCS_DIR#g" \
                | sed -E "s#\\{\\\$HTTPLOGS_DIR\\}#$HTTPLOGS_DIR#g" \
		| sed -E "s#\\{\\\$HOSTNAME\\}#$HOSTNAME#g" \
		| sed -E "s#\\{\\\$USER\\}#$USER#g" \
		| sed -E "s#\\{\\\$VHOST_ONDOMAIN\\}#$VHOST_ONDOMAIN#g" \
		| sed -E "s#\\{\\\$SERVER_ALIASES\\}#$SERVER_ALIASES#g" \
		| sed -E "s#\\{\\\$APACHE_HTTP\\}#$APACHE_HTTP#g" \
		| sed -E "s#\\{\\\$APACHE_HTTPS\\}#$APACHE_HTTPS#g" \
		| tr '\r' '\n' 
}

apache_template(){
	 cat "../templates/$WEBSERVER/$APACHE_VERSION-vhost.conf.tpl" \
		| sed -E "s#\\{\\\$SERVER_IP\\}#$SERVER_IP#g" \
		| sed -E "s#\\{\\\$VHOST\\}#$VHOST#g" \
		| sed -E "s#\\{\\\$VHOST_HOSTNAME\\}#$VHOST_HOSTNAME#g" \
		| sed -E "s#\\{\\\$ADMIN_EMAIL\\}#$ADMIN_EMAIL#g" \
		| sed -E "s#\\{\\\$VHOSTS_DIR\\}#$VHOSTS_DIR#g" \
                | sed -E "s#\\{\\\$HTTPDOCS_DIR\\}#$HTTPDOCS_DIR#g" \
                | sed -E "s#\\{\\\$HTTPLOGS_DIR\\}#$HTTPLOGS_DIR#g" \
		| sed -E "s#\\{\\\$HOSTNAME\\}#$HOSTNAME#g" \
		| sed -E "s#\\{\\\$USER\\}#$USER#g" \
		| sed -E "s#\\{\\\$VHOST_ONDOMAIN\\}#$VHOST_ONDOMAIN#g" \
		| sed -E "s#\\{\\\$SERVER_ALIASES\\}#$SERVER_ALIASES#g" \
		| sed -E "s#\\{\\\$APACHE_HTTP\\}#$APACHE_HTTP#g" \
		| sed -E "s#\\{\\\$APACHE_HTTPS\\}#$APACHE_HTTPS#g" \
		| sed -E "s#\\tServerAlias\s+\$##g" \
		| tr '\r' '\n' 
}

add_apache_config(){
	echo 'add Apache config for vhost'
	if [ "$( uname )" = 'FreeBSD' ]; then
		VHOST_CONFIG_DIR="/usr/local/etc/$APACHE_VERSION/Vhosts"
		( apache_template > "$VHOST_CONFIG_DIR/$VHOST.conf" ) || exit_with_error "ERROR: creating '$VHOST_CONFIG_DIR/$VHOST.conf'"
		service $APACHE_VERSION restart  2>&1 > /dev/null || exit_with_error "ERROR: restating $APACHE_VERSION"
	elif [ "$( uname )" = 'Linux' ]; then
		VHOST_CONFIG_DIR='/etc/apache2/sites-available'
		VHOST_CONFIG_ENABLED_DIR='/etc/apache2/sites-enabled'
		( apache_template > "$VHOST_CONFIG_DIR/$VHOST" )  || exit_with_error "ERROR: creating '$VHOST_CONFIG_DIR/$VHOST.conf'"
		ln -fs "$VHOST_CONFIG_DIR/$VHOST.conf" "$VHOST_CONFIG_ENABLED_DIR/$VHOST.conf" || \
			exit_with_error "ERROR: linking '$VHOST_CONFIG_DIR/$VHOST.conf' to '$VHOST_CONFIG_ENABLED_DIR/$VHOST.conf'"
		service apache2 restart 2>&1 > /dev/null || exit_with_error "ERROR: restating apache2"
	fi
}

add_nginx_config(){
	echo 'add NGINX config for vhost'
	if [ "$( uname )" = 'FreeBSD' ]; then
		VHOST_CONFIG_DIR="/usr/local/etc/nginx/Vhosts"
		( nginx_template > "$VHOST_CONFIG_DIR/$VHOST.conf" ) || exit_with_error "ERROR: creating '$VHOST_CONFIG_DIR/$VHOST.conf'"
		service nginx restart  2>&1 > /dev/null || exit_with_error "ERROR: restating nginx"
	elif [ "$( uname )" = 'Linux' ]; then
		VHOST_CONFIG_DIR='/etc/nginx/sites-available'
		VHOST_CONFIG_ENABLED_DIR='/etc/nginx/sites-enabled'
		( nginx_template > "$VHOST_CONFIG_DIR/$VHOST" )  || exit_with_error "ERROR: creating '$VHOST_CONFIG_DIR/$VHOST.conf'"
		ln -fs "$VHOST_CONFIG_DIR/$VHOST.conf" "$VHOST_CONFIG_ENABLED_DIR/$VHOST.conf" || \
			exit_with_error "ERROR: linking '$VHOST_CONFIG_DIR/$VHOST.conf' to '$VHOST_CONFIG_ENABLED_DIR/$VHOST.conf'"
		service nginx restart 2>&1 > /dev/null || exit_with_error "ERROR: restating nginx"
	fi
}

html_index_template(){
	cat "../templates/index.html.tpl" \
		| sed -E "s#\\{\\\$SERVER_IP\\}#$SERVER_IP#g" \
		| sed -E "s#\\{\\\$VHOST\\}#$VHOST#g" \
		| sed -E "s#\\{\\\$VHOST_HOSTNAME\\}#$VHOST_HOSTNAME#g" \
		| sed -E "s#\\{\\\$ADMIN_EMAIL\\}#$ADMIN_EMAIL#g" \
		| sed -E "s#\\{\\\$VHOST_HOSTNAME_ALIASES\\}#`echo $VHOST_HOSTNAME_ALIASES | sed -E "s#[[:space:]]+#<br/>#g"`#g" \
		| sed -E "s#\\{\\\$HOSTNAME\\}#$HOSTNAME#g" \
		| tr '\r' '\n' 
}


echo 'Copy standard vhost data to VHOST path'
cp -rp ../templates/empty-vhost.dir/* "$VHOSTS_DIR/$VHOST/" || exit_with_error "ERROR: coping standard empty vhost to '$VHOSTS_DIR/$VHOST'"
if [ "x$HTTPDOCS_DIR" != 'xhttpdocs' ]; then
	mv "$VHOSTS_DIR/$VHOST/httpdocs" "$VHOSTS_DIR/$VHOST/$HTTPDOCS_DIR"
fi
echo 'CREATE VHOST STANDARD INDEX'
( html_index_template > "$VHOSTS_DIR/$VHOST/$HTTPDOCS_DIR/index.html" ) || exit_with_error "ERROR: creating '$VHOSTS_DIR/$VHOST/$HTTPDOCS_DIR/index.html'"
echo 'CREATE VHOST HTTP CONFIGURATION'
chown -R "$USER":"$WWW_GROUP" "$VHOSTS_DIR/$VHOST" || exit_with_error "ERROR: coping changing ownership of '$VHOSTS_DIR/$VHOST'"
if [ "x$WEBSERVER" = 'xapache' ]; then
	add_apache_config
elif [ "x$WEBSERVER" = 'xnginx' ]; then
	add_nginx_config
elif [ "x$WEBSERVER" = 'xnginx+apache' ]; then
	add_apache_config
	add_nginx_config
fi
echo 'UPDATE account.txt'
( printf "\n\nHTTP VHOST:\n\tServerName: $VHOST\n$SERVER_ALIASES" \
	|  tr '\r' '\n' \
	>> $VHOST_ACCOUNTFILE ) || exit_with_error "ERROR: updating VHOST http '$VHOST_ACCOUNTFILE'"

cd "$PWD_SRC"
exit 0
