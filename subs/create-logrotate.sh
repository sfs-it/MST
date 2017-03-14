#~/bin/sh
#
# SFS.it Maintenance Server Tools 
# BSD style KISS scripts
#
# REATE LOGROTATE CONFIG FOR VHOST FORCED TO USER
#
# Written by Agostino Zanutto (agostino@sfs.it) for SFS.it MST
#

# USAGE: create-smb-share.sh VHOST 
BASESCRIPT="$(basename $0)"
SYNTAX="$BASESCRIPT VHOST"

SETTINGS_FILE="/etc/SFSit_MST.conf.sh"
test -s "/root/SFSit_MST.conf.sh" && SETTINGS_FILE="/root/SFSit_MST.conf.sh"
if [ -s "$SETTINGS_FILE" ]; then
	VHOSTS_DIR="$(sh "$SETTINGS_FILE" VHOSTS_DIR)"
	WWW_GROUP="$(sh "$SETTINGS_FILE" WWW_GROUP)"
        WEBSERVER="$(sh "$SETTINGS_FILE" WEBSERVER)"
        [ "x$WEBSERVER" != 'xapache' -a  "x$WEBSERVER" != 'xnginx' -a "x$WEBSERVER" != 'xnginx+apache' ] && WEBSERVER='apache'

fi
PWD_SRC="$(pwd)"
cd $(dirname $0) 
exit_with_error(){
	test 'x' != "x$1" && echo "$1"
	cd "$PWD_SRC"
	exit 1
}

[ "x$1" = 'x' ] && exit_with_error "$SYNTAX : VHOST needed"

if [ "$( uname )" = 'FreeBSD' ]; then
	LOGROTATE_DIR='/usr/local/etc/logrotate.d'
elif [ "$( uname )" = 'Linux' ]; then
	LOGROTATE_DIR='/etc/logrotate.d'
fi
LOGROTATE_TEMPLATE="../templates/$WEBSERVER/logrotate-vhost.tpl"


VHOST=$1
VHOST_ACCOUNTFILE="$VHOSTS_DIR/$VHOST/account.txt";
[ -s "$VHOST_ACCOUNTFILE" ] || exit_with_error "ERROR: CANNOT LOAD 'account.txt' FOR $VHOST"
USER="$(cat "$VHOST_ACCOUNTFILE" | grep 'USER:' | sed 's/^USER:\s*//' | sed 's/^[[:blank:]]*//g')"

( cat "$LOGROTATE_TEMPLATE" \
	| sed -E "s#\\{\\\$VHOSTS_DIR\\}#$VHOSTS_DIR#g" \
	| sed -E "s#\\{\\\$VHOST\\}#$VHOST#g" \
	| sed -E "s#\\{\\\$USER\\}#$USER#g" \
	| sed -E "s#\\{\\\$WWW_GROUP\\}#$WWW_GROUP#g" \
	> "$LOGROTATE_DIR/vhost-$VHOST.conf") || exit_with_error "ERROR: saving 'vhost-$VHOST.conf'"
cd "$PWD_SRC"
exit 0
