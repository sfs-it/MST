#~/bin/sh
#
# SFS.it Maintenance Server Tools 
# BSD style KISS scripts
#
# CREATE SMB SHARE FOR VHOST FORCED TO USER
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
        SAMBA_CONF_FILE='/usr/local/etc/smb4.conf'
        SAMBA_CONF_DIR='/usr/local/etc/smb4.conf.d'
elif [ "$( uname )" = 'Linux' ]; then
        SAMBA_CONF_FILE='/etc/samba/smb.conf'
        SAMBA_CONF_DIR='/etc/samba/smb.conf.d'
fi
SAMBA_VHOSTS_CONF_FILE="$SAMBA_CONF_DIR/vhosts.smb.conf"


VHOST=$1
VHOST_ACCOUNTFILE="$VHOSTS_DIR/$VHOST/account.txt";
[ -s "$VHOST_ACCOUNTFILE" ] || exit_with_error "ERROR: CANNOT LOAD 'account.txt' FOR $VHOST"
USER="$(cat "$VHOST_ACCOUNTFILE" | grep 'USER:' | sed 's/^USER:\s*//' | sed 's/^[[:blank:]]*//g')"

cat "../templates/vhost.smb.conf.tpl" \
	| sed -E "s#\\{\\\$VHOSTS_DIR\\}#$VHOSTS_DIR#g" \
	| sed -E "s#\\{\\\$VHOST\\}#$VHOST#g" \
	| sed -E "s#\\{\\\$USER\\}#$USER#g" \
	| sed -E "s#\\{\\\$WWW_GROUP\\}#$WWW_GROUP#g" \
	> "$SAMBA_CONF_DIR/$VHOST.smb.conf" || exit_with_error "ERROR: saving '$VHOST.smb.conf'"
echo "include = $SAMBA_CONF_DIR/$VHOST.smb.conf" >> $SAMBA_VHOSTS_CONF_FILE  || exit_with_error "ERROR: updating '$( basename $SAMBA_VHOSTS_CONF_FILE )'"
if [ "$( uname )" = 'FreeBSD' ]; then
	service samba_server restart || exit_with_error "ERROR: restating smb"
elif [ "$( uname )" = 'Linux' ]; then
	service smbd restart || exit_with_error "ERROR: restating smb"
fi

cd "$PWD_SRC"
exit 0
