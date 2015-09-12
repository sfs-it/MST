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
test -s "~/SFSit_MST.conf.sh" && SETTINGS_FILE="~/SFSit_MST.conf.sh"
if [ -s "$SETTINGS_FILE" ]; then
	HOSTNAME="$(sh "$SETTINGS_FILE" HOSTNAME)"
	test "x$HOSTNAME" = "x" && HOSTNAME=$(hostname)
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
USER=$(cat $VHOST_ACCOUNTFILE | grep 'USER:' | sed 's/^USER:\s*//')
DOMAIN=$(cat $VHOST_ACCOUNTFILE | grep 'DOMAIN:' | sed 's/^DOMAIN:\s*//')
ADMIN_EMAIL=$(cat $VHOST_ACCOUNTFILE | grep 'ADMIN_EMAIL:' | sed 's/^ADMIN_EMAIL:\s*//')
VHOST_ONDOMAIN=$(echo $VHOST | sed -E 's/(\.[^\.]*)$//')

cp -rp ../templates/empty-vhost.dir/* "$VHOSTS_DIR/$VHOST/" || exit_with_error "ERROR: coping standard empty vhost to '$VHOSTS_DIR/$VHOST'"
chown -R "$USER":"$WWW_GROUP" "$VHOSTS_DIR/$VHOST" || exit_with_error "ERROR: coping changing ownership of '$VHOSTS_DIR/$VHOST'"
( cat "../templates/vhost.conf.tpl" \
	| sed -E "s#\\{\\\$VHOST\\}#$VHOST#g" \
	| sed -E "s#\\{\\\$DOMAIN\\}#$DOMAIN#g" \
	| sed -E "s#\\{\\\$MY_DOMAIN\\}#$MY_DOMAIN#g" \
	| sed -E "s#\\{\\\$ADMIN_EMAIL\\}#$ADMIN_EMAIL#g" \
	| sed -E "s#\\{\\\$VHOSTS_DIR\\}#$VHOSTS_DIR#g" \
	| sed -E "s#\\{\\\$HOSTNAME\\}#$HOSTNAME#g" \
	| sed -E "s#\\{\\\$USER\\}#$USER#g" \
	| sed -E "s#\\{\\\$VHOST_ONDOMAIN\\}#$VHOST_ONDOMAIN#g" \
	> "/etc/apache2/sites-available/$VHOST" )  || exit_with_error "ERROR: creating '/etc/apache2/sites-available/$VHOST'"
ln -fs "/etc/apache2/sites-available/$VHOST" "/etc/apache2/sites-enabled/$VHOST"  || exit_with_error "ERROR: linking '/etc/apache2/sites-available/$VHOST' to '/etc/apache2/sites-enabled/$VHOST'"
service apache2 restart || exit_with_error "ERROR: restating apache2"
cd "$PWD_SRC"
exit 0