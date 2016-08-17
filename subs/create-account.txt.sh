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
	MY_DOMAIN="$(sh "$SETTINGS_FILE" MY_DOMAIN)"
	WWW_GROUP="$(sh "$SETTINGS_FILE" WWW_GROUP)"
	WWW_GID="$(id -g $WWW_GROUP)"
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


VHOST=$1
USER=$2
#UID="$(id -u $USER)"
PWD_FTP=$3
PWD_MYSQL=$4
if [ ! -d "$VHOSTS_DIR/$VHOST" ]; then
	mkdir -p "$VHOSTS_DIR/$VHOST" || exit_with_error "ERROR CREATING account.txt FOR VHOST: '$VHOST'"
fi
[ -e  "$VHOSTS_DIR/$VHOST/account.txt" ] && exit_with_error "FILE ACCOUNT already exists"
( cat "../templates/create-account.txt.tpl" \
    | sed -E "s/\\{\\\$HOSTNAME\\}/$HOSTNAME/g" \
    | sed -E "s/\\{\\\$VHOST\\}/$VHOST/g" \
    | sed -E "s;\\{\\\$VHOST_DIR\\};$VHOST_DIR;g" \
    | sed -E "s/\\{\\\$USER\\}/$USER/g" \
    | sed -E "s/\\{\\\$GROUP\\}/$WWW_GROUP/g" \
    | sed -E "s/\\{\\\$GID\\}/$WWW_GID/g" \
    | sed -E "s/\\{\\\$PWD_FTP\\}/$(echo $PWD_FTP | sed -E 's;&;\\&;g')/g" \
    | sed -E "s/\\{\\\$PWD_MYSQL\\}/$(echo $PWD_MYSQL | sed -E 's;&;\\&;g')/g" \
    | sed -E "s/\\{\\\$VHOST_EMAIL\\}/$HOST_EMAIL/g" \
    | sed -E "s/\\{\\\$ADMIN_EMAIL\\}/$ADMIN_EMAIL/g" \
    > "$VHOSTS_DIR/$VHOST/account.txt" ) || exit_with_error "ERROR CREATING account.txt FOR VHOST: '$VHOST'"
chmod 600 "$VHOSTS_DIR/$VHOST/account.txt"
#NOT YET CREATED
# chown "$USER":"$WWW_GROUP" "$VHOSTS_DIR/$VHOST/account.txt"
cd "$PWD_SRC"
exit 0
