#~/bin/sh
#
# SFS.it Maintenance Server Tools 
# BSD style KISS scripts
#
# SEND MAIL TO DOMAIN ADMINISTRATOR FOR ACCOUNT on VHOST
#
# Written by Agostino Zanutto (agostino@sfs.it) for SFS.it MST
#

# USAGE create-sendmail.sh VHOST
SYNTAX="$BASESCRIPT VHOST" 

BASESCRIPT="$(basename $0)"
DIRSCRIPT="$(dirname $0)/../"
. $DIRSCRIPT/mst_sendmail.sh


SETTINGS_FILE="/etc/SFSit_MST.conf.sh"
test -s "~/SFSit_MST.conf.sh" && SETTINGS_FILE="~/SFSit_MST.conf.sh"
if [ -s "$SETTINGS_FILE" ]; then
	HOSTNAME="$(sh "$SETTINGS_FILE" HOSTNAME)"
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
VHOST_EMAIL="$( cat "$VHOST_ACCOUNTFILE" | grep 'VHOST_EMAIL:' | sed 's/^VHOST_EMAIL:\s*//' | sed 's/^[[:blank:]]*//g' )"
test "x$VHOST_EMAIL" = "x" && VHOST_EMAIL="$(sh "$SETTINGS_FILE" HOST_EMAIL)"
ADMIN_EMAIL="$( cat "$VHOST_ACCOUNTFILE" | grep 'ADMIN_EMAIL:' | sed 's/^ADMIN_EMAIL:\s*//' | sed 's/^[[:blank:]]*//g' )"
test "x$ADMIN_EMAIL" = "x" && ADMIN_EMAIL="$(sh "$SETTINGS_FILE" ADMIN_EMAIL)"

mst_sendmail "$VHOST_EMAIL" "$ADMIN_EMAIL" "new user created for $HOSTNAME" "$VHOST_ACCOUNTFILE" || exit_with_error "ERROR: on SENDING EMAIL TO '$ADMIN_EMAIL'"
cd "$PWD_SRC"
exit 0;
