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
test -s "~/SFSit_MST.conf.sh" && SETTINGS_FILE="~/SFSit_MST.conf.sh"
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

VHOST=$1
VHOST_ACCOUNTFILE="$VHOSTS_DIR/$VHOST/account.txt";
[ -s "$VHOST_ACCOUNTFILE" ] || exit_with_error "ERROR: CANNOT LOAD 'account.txt' FOR $VHOST"

rm -f "/etc/samba/smb.conf.d/$VHOST.smb.conf"
cat /etc/samba/smb.conf.vhosts | sed -E "s;include = /etc/samba/smb.conf.d/$VHOST.smb.conf;;" | sed -E '/^$/d' >> /etc/samba/smb.conf.vhosts.tmp
mv -f /etc/samba/smb.conf.vhosts.tmp /etc/samba/smb.conf.vhosts

service smbd restart

cd "$PWD_SRC"
exit 0