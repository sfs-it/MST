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
test -s "~/SFSit_MST.conf.sh" && SETTINGS_FILE="~/SFSit_MST.conf.sh"
if [ -s "$SETTINGS_FILE" ]; then
	HOSTNAME="$(sh "$SETTINGS_FILE" HOSTNAME)"
	test "x$HOSTNAME" = "x" && HOSTNAME="$(hostname)"
	HOST_EMAIL="$(sh "$SETTINGS_FILE" HOST_EMAIL)"
	ADMIN_EMAIL="$(sh "$SETTINGS_FILE" ADMIN_EMAIL)"
	VHOSTS_DIR="$(sh "$SETTINGS_FILE" VHOSTS_DIR)"
	MY_DOMAIN="$(sh "$SETTINGS_FILE" MY_DOMAIN)"
	WWW_GROUP="$(sh "$SETTINGS_FILE" WWW_GROUP)"
	WWW_GID="$(id -g $WWW_GROUP)"
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
[ "x$5" != 'x' ] && HOST_EMAIL="$5"
[ "x$6" != 'x' ] && ADMIN_EMAIL="$6"
[ "x$7" != 'x' ] && GRIVE_EMAIL="$7"
[ "x$8" != 'x' ] && GRIVE_DIR="$8"
[ "x$9" != 'x' ] && GRIVE_SUBDIR_BACKUPS="$9"


VHOST=$1
USER=$2
UID="$(id -u $USER)"
PWD_FTP=$3
PWD_MYSQL=$4
DOMAIN=`echo $VHOST | sed -E 's/([^\.]*\.)*([^\.]*\.[^\.]*)$/\2/'`
VHOST_ONDOMAIN=`echo $VHOST | sed -E 's/(\.[^\.]*)$//'`
if [ ! -d "$VHOSTS_DIR/$VHOST" ]; then
	mkdir -p "$VHOSTS_DIR/$VHOST" || exit_with_error "ERROR CREATING account.txt FOR VHOST: '$VHOST'"
fi
( cat "../templates/create-account.txt.tpl" \
    | sed -E "s/\\{\\\$HOSTNAME\\}/$HOSTNAME/g" \
    | sed -E "s/\\{\\\$DOMAIN\\}/$DOMAIN/g" \
    | sed -E "s/\\{\\\$VHOST\\}/$VHOST/g" \
    | sed -E "s;\\{\\\$VHOST_DIR\\};$VHOST_DIR;g" \
    | sed -E "s/\\{\\\$VHOST_ONDOMAIN\\}/$VHOST_ONDOMAIN/g" \
    | sed -E "s/\\{\\\$MY_DOMAIN\\}/$MY_DOMAIN/g" \
    | sed -E "s/\\{\\\$USER\\}/$USER/g" \
    | sed -E "s/\\{\\\$GROUP\\}/$WWW_GROUP/g" \
    | sed -E "s/\\{\\\$GID\\}/$WWW_GID/g" \
    | sed -E "s/\\{\\\$PWD_FTP\\}/$(echo $PWD_FTP | sed -E 's;&;\\&;g')/g" \
    | sed -E "s/\\{\\\$PWD_MYSQL\\}/$(echo $PWD_MYSQL | sed -E 's;&;\\&;g')/g" \
    | sed -E "s/\\{\\\$VHOST_EMAIL\\}/$HOST_EMAIL/g" \
    | sed -E "s/\\{\\\$ADMIN_EMAIL\\}/$ADMIN_EMAIL/g" \
    | sed -E "s/\\{\\\$GRIVE_EMAIL\\}/$GRIVE_EMAIL/g" \
    | sed -E "s;\\{\\\$GRIVE_DIR\\};$GRIVE_DIR;g" \
    | sed -E "s;\\{\\\$GRIVE_SUBDIR_BACKUPS\\};$GRIVE_SUBDIR_BACKUPS;g" \
    > "$VHOSTS_DIR/$VHOST/account.txt" ) || exit_with_error "ERROR CREATING account.txt FOR VHOST: '$VHOST'"
chmod 600 "$VHOSTS_DIR/$VHOST/account.txt"
#NOT YET CREATED
# chown "$USER":"$WWW_GROUP" "$VHOSTS_DIR/$VHOST/account.txt"
cd "$PWD_SRC"
exit 0
