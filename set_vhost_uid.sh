#!/bin/sh
#
# SFS.it Maintenance Server Tools 
# BSD style KISS scripts
#
# UPDATE VHOST UID
#
# Written by Agostino Zanutto (agostino@sfs.it) for SFS.it MST
#

#SYNTAX: set_vhost_uid.sh VHOST
BASESCRIPT="$(basename $0)"
SYNTAX="$0 [VHOST]"

PWD_SRC="$(pwd)"
SETTINGS_FILE="/etc/SFSit_MST.conf.sh"
test -s "/root/SFSit_MST.conf.sh" && SETTINGS_FILE="/root/SFSit_MST.conf.sh"
if [ -s "$SETTINGS_FILE" ]; then
	VHOSTS_DIR="$(sh "$SETTINGS_FILE" VHOSTS_DIR)"
	WWW_GROUP="$(sh "$SETTINGS_FILE" WWW_GROUP)"
	HTTPDOCS_DIR="$(sh "$SETTINGS_FILE" HTTPDOCS_DIR)"
fi

exit_with_error(){
	test 'x' != "x$1" && echo "$1"
	cd "$PWD_SRC"
	exit 1
}


VHOST="NONE"

if [ "x$1" != "x" ]; then
	VHOST=$1
fi


if cd "$VHOSTS_DIR/$VHOST"; then
	if [ ! -f "account.txt" ]; then 
		exit_with_error "NO account.txt for $VHOST"
	fi
	USER="$(cat "account.txt" | grep '^USER:' | sed -E 's/^USER:\s*//' | sed 's/^[[:blank:]]*//g')"
	UID="$(cat "account.txt" | grep '^UID:' | sed 's/^UID:\s*//' | sed 's/^[[:blank:]]*//g')"
	echo "SET VHOST USER: \"$USER\" TO UID: \"$UID\""
	CURRENT_UID="$(ls -nl "$VHOSTS_DIR" | grep "$VHOST" | awk '{ print $3; }')"
	chown $UID "$VHOSTS_DIR/$VHOST"
	find . -uid $CURRENT_UID -exec chown $UID {} \;
fi
cd $PWD_SRC
#EOF