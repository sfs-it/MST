#~/bin/sh
#
# SFS.it Maintenance Server Tools 
# BSD style KISS scripts
#
# SEND MAIL TO DOMAIN ADMINISTRATOR FOR DELETING ACCOUNT on VHOST
#
# Written by Agostino Zanutto (agostino@sfs.it) for SFS.it MST
#

# USAGE destroy-sendmail.sh VHOST
SYNTAX="$BASESCRIPT VHOST" 

BASESCRIPT="$(basename $0)"
DIRSCRIPT="$(dirname $0)/../"
. $DIRSCRIPT/mst_sendmail.sh

SETTINGS_FILE="/etc/SFSit_MST.conf.sh"
test -s "/root/SFSit_MST.conf.sh" && SETTINGS_FILE="/root/SFSit_MST.conf.sh"
if [ -s "$SETTINGS_FILE" ]; then
	HOSTNAME="$(sh "$SETTINGS_FILE" HOSTNAME)"
	VHOSTS_DIR="$(sh "$SETTINGS_FILE" VHOSTS_DIR)"
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
[ "x$1" = 'x' ] && exit_with_error "$SYNTAX : VHOST needed"

VHOST=$1
VHOST_ACCOUNTFILE="$VHOSTS_DIR/$VHOST/account.txt";
[ -s "$VHOST_ACCOUNTFILE" ] || exit_with_error "ERROR: CANNOT LOAD 'account.txt' FOR $VHOST"
USER=$(cat $VHOST_ACCOUNTFILE | grep 'USER:' | sed 's/^USER:\s*//' | sed 's/^[[:blank:]]*//g')
UID="$(id -u $USER | sed 's/^[[:blank:]]*//g')"
DOMAIN=$(cat $VHOST_ACCOUNTFILE | grep 'DOMAIN:' | sed 's/^DOMAIN:\s*//' | sed 's/^[[:blank:]]*//g')
VHOST_EMAIL="$( cat "$VHOST_ACCOUNTFILE" | grep 'VHOST_EMAIL:' | sed 's/^VHOST_EMAIL:\s*//' | sed 's/^[[:blank:]]*//g')"
test "x$VHOST_EMAIL" = "x" && VHOST_EMAIL="$(sh "$SETTINGS_FILE" HOST_EMAIL)"
ADMIN_EMAIL="$( cat "$VHOST_ACCOUNTFILE" | grep 'ADMIN_EMAIL:' | sed 's/^ADMIN_EMAIL:\s*//' | sed 's/^[[:blank:]]*//g')"
test "x$ADMIN_EMAIL" = "x" && ADMIN_EMAIL="$(sh "$SETTINGS_FILE" ADMIN_EMAIL)"
TIMEMARKFILE="/tmp/mailbody-$(date "+%Y%m%d%H%M%S%N").mail"
( cat ../templates/destroy-mail.tpl \
    | sed -E "s/\\{\\\$HOSTNAME\\}/$HOSTNAME/g" \
    | sed -E "s/\\{\\\$DOMAIN\\}/$DOMAIN/g" \
    | sed -E "s/\\{\\\$VHOST\\}/$VHOST/g" \
    | sed -E "s/\\{\\\$USER\\}/$USER/g" \
    | sed -E "s/\\{\\\$UID\\}/$UID/g" \
    | sed -E "s/\\{\\\$GROUP\\}/$WWW_GROUP/g" \
    | sed -E "s/\\{\\\$GID\\}/$WWW_GID/g" \
    > $TIMEMARKFILE )
mst_sendmail "$VHOST_EMAIL" "$ADMIN_EMAIL" "user deleted from $HOSTNAME" "$TIMEMARKFILE"
rm "$TIMEMARKFILE"
cd "$PWD_SRC"
exit 0;


