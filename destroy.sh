#~/bin/sh
#
# SFS.it Maintenance Server Tools 
# BSD style KISS scripts
#
# DESTROY ACCOUNT on VHOST
#
# Written by Agostino Zanutto (agostino@sfs.it) for SFS.it MST
#

# USAGE destroy.sh VHOST
BASESCRIPT="$(basename $0)"
SYNTAX="$BASESCRIPT VHOST" 

SETTINGS_FILE="/etc/SFSit_MST.conf.sh"
test -s "/root/SFSit_MST.conf.sh" && SETTINGS_FILE="/root/SFSit_MST.conf.sh"
if [ -s "$SETTINGS_FILE" ]; then
	HOSTNAME="$(sh "$SETTINGS_FILE" HOSTNAME)"
	VHOSTS_DIR="$(sh "$SETTINGS_FILE" VHOSTS_DIR)"
	GRIVE_EMAIL="$(sh "$SETTINGS_FILE" GRIVE_EMAIL)"
	GRIVE_DIR="$(sh "$SETTINGS_FILE" GRIVE_DIR)"
	GRIVE_SUBDIR_BACKUPS="$( sh "$SETTINGS_FILE" GRIVE_SUBDIR_BACKUPS | sed -E 's;^(/*)(.*[^/])*(/*)$;\2;g' )"
	[ "x$GRIVE_DIR" = "x" ] &&  GRIVE_DIR="$VHOSTS_DIR/gDrive"
	[ "x$GRIVE_SUBDIR_BACKUPS" = "x" ] &&  GRIVE_SUBDIR_BACKUPS="backups"
fi
PWD_SRC="$(pwd)"
cd $(dirname $0) 
exit_with_error(){
	test 'x' != "x$1" && echo "$1"
	cd "$PWD_SRC"
	exit 1
}
if [ "x$1" = "xBACKUP" ]; then
	BACKUP="BACKUP"
	[ "x$2" != "x" ] && VHOST=$2
else
	BACKUP=""
	VHOST=$1
fi

[ "x$VHOST" = 'x' ] && exit_with_error "$SYNTAX : VHOST needed"


VHOST_ACCOUNTFILE="$VHOSTS_DIR/$VHOST/account.txt";
[ -s "$VHOST_ACCOUNTFILE" ] || exit_with_error "ERROR: CANNOT LOAD 'account.txt' FOR $VHOST"
USER=$(cat $VHOST_ACCOUNTFILE | grep 'USER:' | sed 's/^USER:\s*//')
ADMIN_EMAIL="$(cat "$VHOST_ACCOUNTFILE"| grep 'ADMIN_EMAIL:' | sed 's/^ADMIN_EMAIL:\s*//')"

if [ "x$BACKUP" = "xBACKUP" ]; then
	sh ./backup.sh "$VHOST" || exit_with_error
	echo "backuped '$VHOST'"
fi
sh ./subs/destroy-vhost.sh "$VHOST" || exit_with_error
echo "destroyed vhost '$VHOST'"
[ "x$samba_enabled" = "xYES" ] && ( sh ./subs/destroy-smb-share.sh "$VHOST" || exit_with_error )
echo "removed smb share of '$VHOST'"
sh ./subs/destroy-db.sh "$VHOST" || exit_with_error
echo "destroyed db '$USER'"
sh ./subs/destroy-logrotate.sh "$VHOST" || exit_with_error
echo "logrotate config removed '$VHOST'"
sh ./subs/destroy-sendmail.sh "$VHOST" || exit_with_error
echo "sent email to $ADMIN_EMAIL" 
USER_GRIVE_EMAIL="$(cat $VHOST_ACCOUNTFILE | grep 'GRIVE_EMAIL:' | sed 's/^GRIVE_EMAIL:\s*//')"
if [ "x$GRIVE_EMAIL" = "x$USER_GRIVE_EMAIL" -o "x" = "x$USER_GRIVE_EMAIL" ]; then
	removeFlag='-r'
else
	removeFlag=''
fi
userdel $removeFlag "$USER" || exit_with_error
echo "removed user '$USER'"
exit 1