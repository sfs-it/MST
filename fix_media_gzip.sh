#!/bin/sh
#
# SFS.it Maintenance Server Tools 
# BSD style KISS scripts
#
# UPDATE GZip files for nginix cache
#
# Written by Agostino Zanutto (agostino@sfs.it) for SFS.it MST
#

# USAGE fix_joomla_mod.sh VHOST
BASESCRIPT="$(basename $0)"
SYNTAX="$BASESCRIPT VHOST [DEVEL]"

PWD_SRC="$(pwd)"

SETTINGS_FILE="/etc/SFSit_MST.conf.sh"
test -s "/root/SFSit_MST.conf.sh" && SETTINGS_FILE="/root/SFSit_MST.conf.sh"
if [ -s "$SETTINGS_FILE" ]; then
	VHOSTS_DIR="$(sh "$SETTINGS_FILE" VHOSTS_DIR)"
	WWW_USER="$(sh "$SETTINGS_FILE" WWW_USER)"
	WWW_GROUP="$(sh "$SETTINGS_FILE" WWW_GROUP)"
	HTTPDOCS_DIR="$(sh "$SETTINGS_FILE" HTTPDOCS_DIR)"
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
USER="$(cat $VHOST_ACCOUNTFILE | grep 'USER:' | sed 's/^USER:\s*//' | sed 's/^[[:blank:]]*//g')"

if [ "$( uname )" = 'FreeBSD' ]; then
	CHMOD_OPTIONS=''
	CHOWN_OPTIONS=''
elif [ "$( uname )" = 'Linux' ]; then
	CHMOD_OPTIONS='-c'
	CHOWN_OPTIONS='-c'
fi

cd "$VHOSTS_DIR/$VHOST/$HTTPDOCS_DIR"
USE_FTP=$(cat configuration.php | grep ftp_enable | grep -v -E -e '\s*\/\/' | sed -E -e "s/([^']*')([^'])('.*)/\2/")
if [ "x$USE_FTP" = "x0" ]; then
	echo 'USE FTP OFF'
	USER=$WWW_USER
fi

echo "CREATE static compressed .gz copy of of css,js and html files when needed in $VHOSTS_DIR/$VHOST/$HTTPDOCS_DIR/media/"
echo "USER: ${USER}:${WWW_GROUP}"
find ./media \
	-type file -size +1000c \
	\( -name "*.css" -o -name "*.js" -o -name "*.html" \) \
	\( -exec test -e "{}.gz" -a ! "{}" -ot "{}.gt" \; \
		-o \( \
			-exec echo "{} => {}.gz" \; \
			-exec gzip -k -f "{}" \; \
			-exec chmod $CHMOD_OPTIONS 640 "{}.gz" \; \
			-exec chown $CHOWN_OPTIONS ${USER}:${WWW_GROUP} "{}.gz" \; \
		\) \
	\)
cd "$PWD_SRC"
exit 0
