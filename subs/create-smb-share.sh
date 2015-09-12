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
test -s "~/SFSit_MST.conf.sh" && SETTINGS_FILE="~/SFSit_MST.conf.sh"
if [ -s "$SETTINGS_FILE" ]; then
	VHOSTS_DIR="$(sh "$SETTINGS_FILE" VHOSTS_DIR)"
fi
PWD_SRC="$(pwd)"
cd $(dirname $0) 
exit_with_error(){
	test 'x' != "x$1" && echo "$1"
	cd "$PWD_SRC"
	exit 1
}

[ "x$1" = 'x' ] && exit_with_error "$SYNTAX : VHOST needed"

VHOST=$1
VHOST_ACCOUNTFILE="$VHOSTS_DIR/$VHOST/account.txt";
[ -s "$VHOST_ACCOUNTFILE" ] || exit_with_error "ERROR: CANNOT LOAD 'account.txt' FOR $VHOST"
USER="$(cat "$VHOST_ACCOUNTFILE" | grep 'USER:' | sed 's/^USER:\s*//')"

cat "../templates/vhost.smb.conf.tpl" \
	| sed -E "s#\\{\\\$VHOSTS_DIR\\}#$VHOSTS_DIR#g" \
	| sed -E "s#\\{\\\$VHOST\\}#$VHOST#g" \
    | sed -E "s#\\{\\\$USER\\}#$USER#g" \
	> "/etc/samba/smb.conf.d/$VHOST.smb.conf" || exit_with_error "ERROR: saving '$VHOST.smb.conf'"
echo "include = /etc/samba/smb.conf.d/$VHOST.smb.conf" >> /etc/samba/smb.conf.vhosts  || exit_with_error "ERROR: updating 'smb.conf.vhosts'"
service smbd restart || exit_with_error "ERROR: restating smb"
cd "$PWD_SRC"
exit 0
