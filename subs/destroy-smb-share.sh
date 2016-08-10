#~/bin/sh
#
# SFS.it Maintenance Server Tools 
# BSD style KISS scripts
#
# DESTROY USER WITH PASSWORD PWD_MYSQL, AND DB FOR USER ON MYSQL
#
# Written by Agostino Zanutto (agostino@sfs.it) for SFS.it MST
#

# USAGE destriy-samba.sh USER PWD_MYSQL 
BASESCRIPT="$(basename $0)"
SYNTAX="$BASESCRIPT USER PWD_MYSQL"

SETTINGS_FILE="/etc/SFSit_MST.conf.sh"
test -s "/root/SFSit_MST.conf.sh" && SETTINGS_FILE="/root/SFSit_MST.conf.sh"
if [ -s "$SETTINGS_FILE" ]; then
	VHOSTS_DIR="$(sh "$SETTINGS_FILE" VHOSTS_DIR)"
	MYSQL_ROOT_PWD="$(sh "$SETTINGS_FILE" MYSQL_ROOT_PWD)"
fi
PWD_SRC="$(pwd)"
cd $(dirname $0) 
exit_with_error(){
	test 'x' != "x$1" && echo "$1"
	cd "$PWD_SRC"
	exit 1
}

[ "x$1" = 'x' ] && exit_with_error "$SYNTAX : VHOST needed"
if [ "$( uname )" = 'FreeBSD' ]; then
        SAMBA_CONF_DIR='/usr/local/etc/smb4.conf.d'
elif [ "$( uname )" = 'Linux' ]; then
        SAMBA_CONF_DIR='/etc/samba/smb.conf.d'
fi
SAMBA_VHOSTS_CONF_FILE="$SAMBA_CONF_DIR/vhosts.smb.conf"


VHOST=$1
VHOST_ACCOUNTFILE="$VHOSTS_DIR/$VHOST/account.txt";
[ -s "$VHOST_ACCOUNTFILE" ] || exit_with_error "ERROR: CANNOT LOAD 'account.txt' FOR $VHOST"
USER="$(cat "$VHOST_ACCOUNTFILE" | grep 'USER:' | sed 's/^USER:\s*//' | sed 's/^[[:blank:]]*//g')"


rm -f "/etc/samba/smb.conf.d/$VHOST.smb.conf"
cat $SAMBA_VHOSTS_CONF_FILE | sed -E "s;include = $SAMBA_CONF_DIR/$VHOST.smb.conf;;" | sed -E '/^$/d' >> $SAMBA_VHOSTS_CONF_FILE.tmp
mv -f $SAMBA_VHOSTS_CONF_FILE.tmp $SAMBA_VHOSTS_CONF_FILE

if [ "$( uname )" = 'FreeBSD' ]; then
        service samba_server restart || exit_with_error "ERROR: restating smb"
elif [ "$( uname )" = 'Linux' ]; then
        service smbd restart || exit_with_error "ERROR: restating smb"
fi

cd "$PWD_SRC"
exit 0
