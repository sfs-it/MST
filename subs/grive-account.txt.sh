#~/bin/sh
#
# SFS.it Maintenance Server Tools 
# BSD style KISS scripts
#
# CREATE REPORT FILE AND PLACE ON VHOST DIR
#
# Written by Agostino Zanutto (agostino@sfs.it) for SFS.it MST
#

# USAGE create-reportfile.sh VHOST USER [PWD_FTP [PWD_MYSQL [ADMIN_EMAIL]]]
BASESCRIPT="$(basename $0)"
SYNTAX="$BASESCRIPT VHOST USER  [PWD_FTP [PWD_MYSQL [HOST_EMAIL [ADMIN_EMAIL]]]]"

SETTINGS_FILE="/etc/SFSit_MST.conf.sh"
test -s "/root/SFSit_MST.conf.sh" && SETTINGS_FILE="/root/SFSit_MST.conf.sh"
if [ -s "$SETTINGS_FILE" ]; then
	HOSTNAME="$(sh "$SETTINGS_FILE" HOSTNAME)"
	test "x$HOSTNAME" = "x" && HOSTNAME="$(hostname)"
	HOST_EMAIL="$(sh "$SETTINGS_FILE" HOST_EMAIL)"
	ADMIN_EMAIL="$(sh "$SETTINGS_FILE" ADMIN_EMAIL)"
	VHOSTS_DIR="$(sh "$SETTINGS_FILE" VHOSTS_DIR)"
        GRIVE_ENABLED="$(sh "$SETTINGS_FILE" GRIVE_ENABLED | tr '[:lower:]' '[:upper:])"
	if [ "x$GRIVE_ENABLED" = 'xYES' ]; then
		GRIVE_EMAIL="$(sh "$SETTINGS_FILE" GRIVE_EMAIL)"
		GRIVE_DIR="$(sh "$SETTINGS_FILE" GRIVE_DIR)"
		GRIVE_SUBDIR_BACKUPS="$(sh "$SETTINGS_FILE" GRIVE_SUBDIR_BACKUPS | sed -E 's;^(/*)(.*[^/])*(/*)$;\2;g')"
		[ 'x' = "$GRIVE_EMAIL" ] && GRIVE_EMAIL="$ADMIN_EMAIL"
		[ 'x' = "$GRIVE_DIR" ] && GRIVE_DIR="$VHOSTS_DIR/gDrive"
		[ 'x' = "$GRIVE_SUBDIR_BACKUPS" ] && GRIVE_SUBDIR_BACKUPS='backups'
	fi
fi
if [ "x$GRIVE_ENABLED" !== 'xYES' ]; then
	exit 0;
fi
PWD_SRC="$(pwd)"
cd $(dirname $0) 
exit_with_error(){
	test 'x' != "x$1" && echo "$1"
	cd "$PWD_SRC"
	exit 1
}

[ "x$1" = 'x' ] && exit_with_error "$SYNTAX: VHOST NEEDED"
VHOST="$1"
[ "x$2" != 'x' ] && GRIVE_EMAIL="$2"
[ "x$3" != 'x' ] && GRIVE_DIR="$3"
[ "x$4" != 'x' ] && GRIVE_SUBDIR_BACKUPS="$4"

VHOST_ACCOUNTFILE="$VHOSTS_DIR/$VHOST/account.txt";
[ -s "$VHOST_ACCOUNTFILE" ] || exit_with_error "ERROR: CANNOT LOAD 'account.txt' FOR $VHOST"

echo 'UPDATE account.txt for GRIVE PARAMTERS'
( printf "\n#GRIVE\n\tGRIVE_EMAIL: $GRIVE_EMAIL\n\tGRIVE_DIR: $GRIVE_DIR\n\tGRIVE_SUBDIR_BACKUPS: $GRIVE_SUBDIR_BACKUPS\n" \
        |  tr '\r' '\n' \
        >> $VHOST_ACCOUNTFILE ) || exit_with_error "ERROR: updating GRIVE paramters '$VHOST_ACCOUNTFILE'"
cd "$PWD_SRC"
exit 0

