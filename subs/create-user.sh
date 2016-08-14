#!/bin/sh
#
# SFS.it Maintenance Server Tools 
# BSD style KISS scripts
#
# CREATE USER AND EMPTY HOMEDIR
#
# Written by Agostino Zanutto (agostino@sfs.it) for SFS.it MST
#

# USAGE create-user.sh VHOST
BASESCRIPT="$(basename $0)"
SYNTAX="$BASESCRIPT VHOST"

PWD_SRC="$(pwd)"

SETTINGS_FILE="/etc/SFSit_MST.conf.sh"
test -s "/root/SFSit_MST.conf.sh" && SETTINGS_FILE="/root/SFSit_MST.conf.sh"
if [ -s "$SETTINGS_FILE" ]; then
	VHOSTS_DIR="$(sh "$SETTINGS_FILE" VHOSTS_DIR)"
	WWW_USER="$(sh "$SETTINGS_FILE" WWW_USER)"
	WWW_GROUP="$(sh "$SETTINGS_FILE" WWW_GROUP)"
fi
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
USER="` cat $VHOST_ACCOUNTFILE | grep 'USER:' | sed 's/^USER:\s*//' | sed 's/^[[:blank:]]*//g' `"
FTP_PWD="` cat $VHOST_ACCOUNTFILE | grep 'PWD_FTP:' | sed 's/^PWD_FTP:\s*//' | sed 's/^[[:blank:]]*//g' `"

test -d "$VHOSTS_DIR/$VHOST" || mkdir -p "$VHOSTS_DIR/$VHOST"
if [ "$( uname )" = 'FreeBSD' ]; then
	WWW_GROUP_ID=`id -g "$WWW_USER"`
	( echo "$USER::$WWW_GROUP_ID:::::$VHOSTS_DIR/$VHOST:/usr/sbin/ftp-only:$FTP_PWD" | adduser -f - ) || \
		exit_with_error "ERROR: CANNOT CREATE USER" 
	UID=`id -u "$USER"`
elif [ "$( uname )" = 'Linux' ]; then
	useradd -d "$VHOSTS_DIR/$VHOST" -g "$WWW_GROUP" -M -s /usr/sbin/ftp-only "$USER" ||  exit_with_error "ERROR: CANNOT CREATE USER"
	( echo "$USER:$FTP_PWD" | chpasswd ) || exit_with_error "ERROR: CANNOT CHANGE THE PASSWORD" 
	UID=`id -u "$USER"`
fi
chown -R "$USER":"$WWW_GROUP" "$VHOSTS_DIR/$VHOST" ||  exit_with_error "ERROR: CHANGING OWNERSHIP OF '$VHOSTS_DIR/$VHOST' TO '$USER:$WWW_GROUP'" 

cat "$VHOST_ACCOUNTFILE" \
	| sed -E "s/\\{\\\$UID\\}/$UID/g" \
	> "$VHOST_ACCOUNTFILE.tmp"
rm "$VHOST_ACCOUNTFILE"
mv "$VHOST_ACCOUNTFILE.tmp" "$VHOST_ACCOUNTFILE"
chown "$USER":"$WWW_GROUP" "$VHOST_ACCOUNTFILE"
cd "$PWD_SRC"
exit 0
