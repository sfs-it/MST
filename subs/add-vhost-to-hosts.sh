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
	HOSTNAME="$(sh "$SETTINGS_FILE" HOSTNAME | tr '[:lower:]' '[:upper:]')"
	test "x$HOSTNAME" = "x" && HOSTNAME=$(hostname)
	SERVER_IP="$(sh "$SETTINGS_FILE" SERVER_IP | tr '[:lower:]' '[:upper:]')"
	test "x$SERVER_IP" = "x" && SERVER_IP="127.0.0.1"
	PUBLIC_IP="$(sh "$SETTINGS_FILE" PUBLIC_IP | tr '[:lower:]' '[:upper:]')"
	test "x$PUBLIC_IP" = "x" && PUBLIC_IP="NONE"
	APACHE_VERSION="$(sh "$SETTINGS_FILE" APACHE_VERSION)"
	[ "x$APACHE_VERSION" != 'xapache22' -a "x$APACHE_VERSION" != 'xapache24' ] && APACHE_VERSION='apache24'
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
if [ "x$PUBLIC_IP" = 'xNONE' ]; then
	echo "YOU NEED TO SET PUBLIC_IP TO FULL USE OF VHOSTS TO /etc/hosts";
	IP=$SERVER_IP
else
	IP=$PUBLIC_IP
fi
VHOST=$1

VHOST_ACCOUNTFILE="$VHOSTS_DIR/$VHOST/account.txt";
[ -s "$VHOST_ACCOUNTFILE" ] || exit_with_error "ERROR: CANNOT LOAD 'account.txt' FOR $VHOST"
USER=$(cat $VHOST_ACCOUNTFILE | grep 'USER:' | sed 's/^USER:\s*//' | sed 's/^[[:blank:]]*//g')
ADMIN_EMAIL=$(cat $VHOST_ACCOUNTFILE | grep 'ADMIN_EMAIL:' | sed 's/^ADMIN_EMAIL:\s*//' | sed 's/^[[:blank:]]*//g')
VHOST_ONDOMAIN=$(echo $VHOST | sed -E 's/(\.[^\.]*)$//' | sed 's/^[[:blank:]]*//g')

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
	VHOST_ALIAS="$(echo $1 | sed 's/^[[:blank:]]*//g')"
	if [ "x$VHOST_ALIAS" != "x" -a "x$VHOST_ALIAS" != "x$VHOST_HOSTNAME" ]; then
		PRESENCE_CHECK=$(printf "$SERVER_ALIASES" | grep "ServerAlias $VHOST_ALIAS")
		if [ "x$PRESENCE_CHECK" = "x" ]; then
			HOST_ALIAS="$(get_host $VHOST_ALIAS)"
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
}
[ "x$(get_1st_level_domain $VHOST)" = 'local' ] || \
	add_aliases "$(change_1st_level_domain $VHOST 'local')"
DOMAIN="$(get_domain $VHOST)"
if [ "x$DEVEL_DOMAIN" != 'x' -a "x$DOMAIN" != "x$DEVEL_DOMAIN" ]; then
	ALIAS_DEVEL_DOMAIN="$(change_1st_level_domain $VHOST $DEVEL_DOMAIN)"
	echo "DEVELOPMENT DOMAIN add '$VHOST' in '$ALIAS_DEVEL_DOMAIN'"
	add_aliases "$ALIAS_DEVEL_DOMAIN"
	DOMAIN="$(get_domain $VHOST_HOSTNAME)"
else
	VHOST_HOSTNAME=$VHOST
fi
HOST="$(get_host $VHOST)"
if [ "x$DOMAIN" != "x" -a \( "x$HOST" = "xwww" \) ]; then
        SERVER_ALIASES="\t$DOMAIN"
	echo "ADD DOMAIN '$DOMAIN' to Server Aliases"
else
        SERVER_ALIASES=""
fi
while [ "x$2" != "x" ]; do
        add_aliases $2
        shift
done


echo 'ADD PUBLIC IP VHOST and ALIASES to /etc/hosts'
printf "\n\n## VHOST IPs ${VHOST} ##\n${IP}\t${VHOST}.local\n${SERVER_IP}\t$VHOST_HOSTNAME$SERVER_ALIASES" >> /etc/hosts 
cd "$PWD_SRC"
exit 0
