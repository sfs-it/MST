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
SYNTAX="$BASESCRIPT JOOMLA_UPDATE_FILE VHOST"

PWD_SRC="$(pwd)"

SETTINGS_FILE="/etc/SFSit_MST.conf.sh"
test -s "/root/SFSit_MST.conf.sh" && SETTINGS_FILE="/root/SFSit_MST.conf.sh"
if [ -s "$SETTINGS_FILE" ]; then
	VHOSTS_DIR="$(sh "$SETTINGS_FILE" VHOSTS_DIR)"
	WWW_USER="$(sh "$SETTINGS_FILE" WWW_USER)"
	WWW_GROUP="$(sh "$SETTINGS_FILE" WWW_GROUP)"
	HTTPDOCS_DIR="$(sh "$SETTINGS_FILE" HTTPDOCS_DIR)"
fi
SCRIPTS_DIR=$(dirname $0) 
exit_with_error(){
	test 'x' != "x$1" && echo "$1"
	cd "$PWD_SRC"
	exit 1
}


echo "######"
echo "# UPDATE $VHOST JOOMLA WITH $JOOMLA_UPDATE_FILE"
echo "###"
[ "x$1" = 'x' ] && exit_with_error "$SYNTAX : 'JOOMLA_UPDATE_FILE' needed";
[ "x$2" = 'x' ] && exit_with_error "$SYNTAX : 'VHOST' needed";
JOOMLA_UPDATE_FILE=$1
VHOST=$2
VHOST_ACCOUNTFILE="$VHOSTS_DIR/$VHOST/account.txt";
[ -s "$VHOST_ACCOUNTFILE" ] || exit_with_error "ERROR: CANNOT LOAD 'account.txt' FOR $VHOST"


if [ "$( uname )" = 'FreeBSD' ]; then
	CHMOD_OPTIONS=''
	CHOWN_OPTIONS=''
elif [ "$( uname )" = 'Linux' ]; then
	CHMOD_OPTIONS='-c'
	CHOWN_OPTIONS='-c'
fi

cd "$VHOSTS_DIR/$VHOST/$HTTPDOCS_DIR"
USE_FTP=$(cat configuration.php | grep ftp_enable | grep -v -E -e '\s*\/\/' | sed -E -e "s/([^']*')([^'])('.*)/\2/")
if [ "x$USE_FTP" = "x1" ]; then
	echo 'USE FTP ON'
	USER="$(cat $VHOST_ACCOUNTFILE | grep 'USER:' | sed 's/^USER:\s*//' | sed 's/^[[:blank:]]*//g')"
else
	echo 'USE FTP OFF'
	USER=$WWW_USER
fi
ext=$(echo $JOOMLA_UPDATE_FILE | sed -E 's/.*(\.(tar\.)?.*)$/\1/')
if [ "x$ext" = "x.zip" ]; then
	unzip -o  "$PWD_SRC/$JOOMLA_UPDATE_FILE"
elif [ "x$ext" = "x.tar.gz" -o "x$ext" = "x.tgz" ]; then
	tar  -xvzf "$PWD_SRC/$JOOMLA_UPDATE_FILE" 
elif [ "x$ext" = = "x.tar.bz2" ]; then
	tar -xvjf "$PWD_SRC/$JOOMLA_UPDATE_FILE" 
else
	exit_with_error "ARCHIVE FILETYPE UNKNOW ${JOOMLA_UPDATE_FILE}" 
fi
echo "JOOMLA UPDATED ON ${VHOST}"
echo "FIX JOOMLA MOD"
if [ "x$USER" = "x$WWW_USER" ]; then
	sh "${SCRIPTS_DIR}/fix_joomla_mod.sh" "$VHOST" DEVEL
else
	sh "${SCRIPTS_DIR}/fix_joomla_mod.sh" "$VHOST"
fi

cd "$PWD_SRC"
exit 0
