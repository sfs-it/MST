#~/bin/sh
#
# SFS.it Maintenance Server Tools 
# BSD style KISS scripts
#
# DESTROY LOGROTATE CONFIG FOR VHOST
#
# Written by Agostino Zanutto (agostino@sfs.it) for SFS.it MST
#

# USAGE destroy-logrotate.sh VHOST
BASESCRIPT="$(basename $0)"
SYNTAX="$BASESCRIPT VHOST"

SETTINGS_FILE="/etc/SFSit_MST.conf.sh"
test -s "/root/SFSit_MST.conf.sh" && SETTINGS_FILE="/root/SFSit_MST.conf.sh"
if [ -s "$SETTINGS_FILE" ]; then
        APACHE_VERSION="$(sh "$SETTINGS_FILE" APACHE_VERSION)"
        [ "x$APACHE_VERSION" != 'xapache22' -a "x$APACHE_VERSION" != 'xapache24' ] && APACHE_VERSION='apache24'
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
if [ "$( uname )" = 'FreeBSD' ]; then
        LOGROTATE_DIR='/usr/local/etc/logrotate.d'
elif [ "$( uname )" = 'Linux' ]; then
        LOGROTATE_DIR='/etc/logrotate.d'
fi


rm "$LOGROTATE_DIR/$APACHE_VERSION-vhost-$VHOST.conf" || exit_with_error "ERROR: erasing logrotate '$APACHE_VERSION-vhost-$VHOST.conf'"
cd "$PWD_SRC"
exit 0
