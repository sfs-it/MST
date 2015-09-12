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

PWD_SRC="$(pwd)"
cd $(dirname $0) 
exit_with_error(){
	test 'x' != "x$1" && echo "$1"
	cd "$PWD_SRC"
	exit 1
}

[ "x$1" = 'x' ] && exit_with_error "$SYNTAX : VHOST needed"

VHOST=$1

rm "/etc/logrotate.d/apache2-vhost-$VHOST" || exit_with_error "ERROR: erasing logrotate 'apache2-vhost-$VHOST'"
cd "$PWD_SRC"
exit 0
