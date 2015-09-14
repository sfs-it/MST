#~/bin/sh#
# SFS.it Maintenance Server Tools 
# BSD style KISS scripts
#
# CREATE VHOST WITH USER,HOMEDIR, DB etc etc etc
#
# Written by Agostino Zanutto (agostino@sfs.it) for SFS.it MST
#
# USAGE VHOST USER [PWD_FTP [PWD_MYSQL [ADMIN_EMAIL]]]
BASESCRIPT="$(basename $0)"
SYNTAX="$BASESCRIPT VHOST USER [PWD_FTP [PWD_MYSQL [HOST_EMAIL [ADMIN_EMAIL [GRIVE_EMAIL [GRIVE_DIR [GRIVE_SUBDIR_BACKUPS]]]]]]]" 

SETTINGS_FILE="/etc/SFSit_MST.conf.sh"
test -s "~/SFSit_MST.conf.sh" && SETTINGS_FILE="~/SFSit_MST.conf.sh"
if [ -s "$SETTINGS_FILE" ]; then
	HOSTNAME="$(sh "$SETTINGS_FILE" HOSTNAME)"
	test "x$HOSTNAME" = "x" && HOSTNAME="$(hostname)"
	VHOSTS_DIR="$(sh "$SETTINGS_FILE" VHOSTS_DIR)"
	HOST_EMAIL="$(sh "$SETTINGS_FILE" ADMIN_EMAIL)"
	ADMIN_EMAIL="$(sh "$SETTINGS_FILE" ADMIN_EMAIL)"
	GRIVE_EMAIL="$(sh "$SETTINGS_FILE" GRIVE_EMAIL)"
	GRIVE_DIR="$(sh "$SETTINGS_FILE" GRIVE_DIR)"
	GRIVE_SUBDIR_BACKUPS="$(sh "$SETTINGS_FILE" GRIVE_SUBDIR_BACKUPS | sed -E 's;^(/*)(.*[^/])*(/*)$;\2;g')"
	[ 'x' = "$GRIVE_EMAIL" ] && GRIVE_EMAIL="$ADMIN_EMAIL"
	[ 'x' = "$GRIVE_DIR" ] && GRIVE_DIR="$VHOSTS_DIR/gDrive"
	[ 'x' = "$GRIVE_SUBDIR_BACKUPS" ] && GRIVE_SUBDIR_BACKUPS='backups'
fi

PWD_SRC="$(pwd)"
cd $(dirname $0) 
exit_with_error(){
	test 'x' != "x$1" && echo "$1"
	cd "$PWD_SRC"
	exit 1
}

[ "x$1" = 'x' ] && exit_with_error "$SYNTAX: VHOST NEEDED"
[ "x$2" = 'x' ] && exit_with_error "$SYNTAX: USER NEEDED"
[ "x$3" = 'x' ] && PWD_FTP=$(./subs/pwd_generator.pl 8)
[ "x$4" = 'x' ] && PWD_MYSQL=$(./subs/pwd_generator.pl 16)
[ "x$5" != 'x' ] && ADMIN_EMAIL="$5"
[ "x$6" != 'x' ] && HOST_EMAIL="$6"
[ "x$7" != 'x' ] && GRIVE_EMAIL="$7"
[ "x$8" != 'x' ] && GRIVE_DIR="$8"
[ "x$9" != 'x' ] && GRIVE_SUBDIR_BACKUPS="$9"

VHOST="$1"
USER="$2"
PWD_FTP="$3"
PWD_MYSQL="$4"
DOMAIN="$(echo "$VHOST" | sed -E 's/([^\.]*\.)*([^\.]*\.[^\.]*)$/\2/')"

VHOST_SFS="$(echo "$VHOST" | sed -E 's/(\.[^\.]*)$//')"
echo "CREATE account.txt file"
sh ./subs/create-account.txt.sh "$VHOST" "$USER" "$PWD_FTP" "$PWD_MYSQL" "$HOST_EMAIL" "$ADMIN_EMAIL" "$GRIVE_EMAIL" "$GRIVE_DIR" "$GRIVE_SUBDIR_BACKUPS" || exit_with_error  "ERROR: CREATING REPORT account.txt"
echo "report 'account.txt' file created"
echo "CREATE $VHOST in $VHOSTS_DIR of $HOSTNAME for $USER with ftp password '$PWD_FTP' and mysql password: '$PWD_MYSQL'"
sh ./subs/create-user.sh "$VHOST" || exit_with_error "ERROR: CREATING USER '$USER'"
echo "user '$USER' created"
sh ./subs/create-vhost.sh "$VHOST" ||exit_with_error "ERROR: CREATING VHOST '$VHOST'"
echo "vhost '$VHOST' created"
sh ./subs/create-db.sh "$VHOST" || exit_with_error "ERROR: CREATING DB for user '$USER'"
echo "db '$USER' created"
sh -x ./subs/create-smb-share.sh "$VHOST" || exit_with_error "ERROR: CREATING SMB SHARE FOR $VHOST"
echo "smb '$VHOST' share created"
sh ./subs/create-logrotate.sh "$VHOST" || exit_with_error "ERROR: CREATING LOG ROTATE FOR $VHOST"
echo "logrotate '$VHOST' share created"
sh ./subs/create-sendmail.sh "$VHOST" || exit_with_error  "ERROR: SENDING REPORT"
echo "email to $ADMIN_EMAIL send"
echo "--- WELL DONE: USER, VHOST, DB, SMB SHARE, REPORT, MAIL SENT---"
cd "$PWD_SRC" 
