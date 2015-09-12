#~/bin/sh
#
# SFS.it Maintenance Server Tools 
# BSD style KISS scripts
#
# CREATE USER WITH PASSWORD PWD_MYSQL, AND DB FOR USER ON MYSQL
#
# Written by Agostino Zanutto (agostino@sfs.it) for SFS.it MST
#

# USAGE create-db.sh USER PWD_MYSQL 
BASESCRIPT="$(basename $0)"
SYNTAX="$BASESCRIPT USER PWD_MYSQL"

SETTINGS_FILE="/etc/SFSit_MST.conf.sh"
test -s "~/SFSit_MST.conf.sh" && SETTINGS_FILE="~/SFSit_MST.conf.sh"
if [ -s "$SETTINGS_FILE" ]; then
	VHOSTS_DIR="$(sh "$SETTINGS_FILE" VHOSTS_DIR)"
fi
PWD_SRC="$(pwd)"
exit_with_error(){
	test 'x' != "x$1" && echo "$1"
	cd "$PWD_SRC"
	exit 1
}

[ "x$1" = 'x' ] && exit_with_error "$SYNTAX : VHOST needed"
[ "x$2" = 'x' -a -s "$2" ] && exit_with_error "$SYNTAX : SQL DUMP to restore needed"
SQL_DUMP="$(readlink -f "$2")"
cd $(dirname $0) 

VHOST=$1
VHOST_ACCOUNTFILE="$VHOSTS_DIR/$VHOST/account.txt";
[ -s "$VHOST_ACCOUNTFILE" ] || exit_with_error "ERROR: CANNOT LOAD 'account.txt' FOR $VHOST"
USER="`cat $VHOST_ACCOUNTFILE | grep 'USER:' | sed 's/^USER:\s*//'`"
PWD_MYSQL="$(cat $VHOST_ACCOUNTFILE | grep 'PWD_MYSQL:' | sed 's/^PWD_MYSQL:\s*//')"
( cat $SQL_DUMP \
	| mysql --user "$USER" --password="$PWD_MYSQL" "$USER" ) || exit_with_error "ERROR: RESTORING DB"
cd "$PWD_SRC"
exit 0
