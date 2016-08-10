#~/bin/sh
#
# SFS.it Maintenance Server Tools 
# BSD style KISS scripts
#
# CREATE USER AND HOMEDIR
#
# Written by Agostino Zanutto (agostino@sfs.it) for SFS.it MST
#

# USAGE create-vhost.sh VHOST USER [ADMIN_EMAIL]
BASESCRIPT="$(basename $0)"
SYNTAX="$BASESCRIPT VHOST USER [ADMIN_EMAIL]"

SETTINGS_FILE="/etc/SFSit_MST.conf.sh"
test -s "/root/SFSit_MST.conf.sh" && SETTINGS_FILE="/root/SFSit_MST.conf.sh"
if [ -s "$SETTINGS_FILE" ]; then
	HOSTNAME="$(sh "$SETTINGS_FILE" HOSTNAME)"
	test "x$HOSTNAME" = "x" && HOSTNAME=$(hostname)
	APACHE_VERSION="$(sh "$SETTINGS_FILE" APACHE_VERSION)"
	[ "x$APACHE_VERSION" != 'xapache22' -a "x$APACHE_VERSION" != 'xapache24' ] && APACHE_VERSION='apache22'
	VHOSTS_DIR="$(sh "$SETTINGS_FILE" VHOSTS_DIR)"
	MY_DOMAIN="$(sh "$SETTINGS_FILE" MY_DOMAIN)"
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
USER=$(cat $VHOST_ACCOUNTFILE | grep 'USER:' | sed 's/^USER:\s*//' | sed 's/^[[:blank:]]*//g')
DOMAIN=$(cat $VHOST_ACCOUNTFILE | grep 'DOMAIN:' | sed 's/^DOMAIN:\s*//' | sed 's/^[[:blank:]]*//g')
ADMIN_EMAIL=$(cat $VHOST_ACCOUNTFILE | grep 'ADMIN_EMAIL:' | sed 's/^ADMIN_EMAIL:\s*//' | sed 's/^[[:blank:]]*//g')
VHOST_ONDOMAIN=$(echo $VHOST | sed -E 's/(\.[^\.]*)$//' | sed 's/^[[:blank:]]*//g')

cp -rp ../templates/empty-vhost.dir/* "$VHOSTS_DIR/$VHOST/" || exit_with_error "ERROR: coping standard empty vhost to '$VHOSTS_DIR/$VHOST'"
chown -R "$USER":"$WWW_GROUP" "$VHOSTS_DIR/$VHOST" || exit_with_error "ERROR: coping changing ownership of '$VHOSTS_DIR/$VHOST'"
if [ "$( uname )" = 'FreeBSD' ]; then
	VHOST_CONFIG_DIR="/usr/local/etc/$APACHE_VERSION/Vhosts"
	( cat "../templates/$APACHE_VERSION.vhost.conf.tpl" \
		| sed -E "s#\\{\\\$VHOST\\}#$VHOST#g" \
		| sed -E "s#\\{\\\$DOMAIN\\}#$DOMAIN#g" \
		| sed -E "s#\\{\\\$MY_DOMAIN\\}#$MY_DOMAIN#g" \
		| sed -E "s#\\{\\\$ADMIN_EMAIL\\}#$ADMIN_EMAIL#g" \
		| sed -E "s#\\{\\\$VHOSTS_DIR\\}#$VHOSTS_DIR#g" \
		| sed -E "s#\\{\\\$HOSTNAME\\}#$HOSTNAME#g" \
		| sed -E "s#\\{\\\$USER\\}#$USER#g" \
		| sed -E "s#\\{\\\$VHOST_ONDOMAIN\\}#$VHOST_ONDOMAIN#g" \
		> "$VHOST_CONFIG_DIR/$VHOST.conf" )  || exit_with_error "ERROR: creating '$VHOST_CONFIG_DIR/$VHOST.conf'"
	service $APACHE_VERSION restart || exit_with_error "ERROR: restating $APACHE_VERSION"
elif [ "$( uname )" = 'Linux' ]; then
	VHOST_CONFIG_DIR='/etc/apache2/sites-available'
	VHOST_CONFIG_ENABLED_DIR='/etc/apache2/sites-enabled'
	( cat "../templates/$APACHE_VERSION.vhost.conf.tpl" \
		| sed -E "s#\\{\\\$VHOST\\}#$VHOST#g" \
		| sed -E "s#\\{\\\$DOMAIN\\}#$DOMAIN#g" \
		| sed -E "s#\\{\\\$MY_DOMAIN\\}#$MY_DOMAIN#g" \
		| sed -E "s#\\{\\\$ADMIN_EMAIL\\}#$ADMIN_EMAIL#g" \
		| sed -E "s#\\{\\\$VHOSTS_DIR\\}#$VHOSTS_DIR#g" \
		| sed -E "s#\\{\\\$HOSTNAME\\}#$HOSTNAME#g" \
		| sed -E "s#\\{\\\$USER\\}#$USER#g" \
		| sed -E "s#\\{\\\$VHOST_ONDOMAIN\\}#$VHOST_ONDOMAIN#g" \
		> "$VHOST_CONFIG_DIR/$VHOST" )  || exit_with_error "ERROR: creating '$VHOST_CONFIG_DIR/$VHOST.conf'"
	ln -fs "$VHOST_CONFIG_DIR/$VHOST.conf" "$VHOST_CONFIG_ENABLED_DIR/$VHOST.conf" || \
		exit_with_error "ERROR: linking '$VHOST_CONFIG_DIR/$VHOST.conf' to '$VHOST_CONFIG_ENABLED_DIR/$VHOST.conf'"
	service apache2 restart || exit_with_error "ERROR: restating apache2"
fi
cd "$PWD_SRC"
exit 0
