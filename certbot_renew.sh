#!/bin/sh
#
# SFS.it Maintenance Server Tools 
# BSD style KISS scripts
#
# FILE MODIFIED CHECKER SINCE N DAYS
#
# Written by Agostino Zanutto (agostino@sfs.it) for SFS.it MST
#

#SYNTAX certbot_renew.sh [nomail]

BASESCRIPT="$(basename $0)"
DIRSCRIPT="$(dirname $0)"
if [ -s "$DIRSCRIPT/SFSit_MST.conf.sh" ]; then
	. "$( readlink -f "$DIRSCRIPT/SFSit_MST.conf.sh" )"
fi
SYNTAX="$BASESCRIPT [nomail]"
PWD=$(pwd)
exit_with_error(){
	test 'x' != "x$1" && echo "$1"
	exit 1
}
. $DIRSCRIPT/mst_sendmail.sh

#
## INIT PARAMETERS
##

umask 022

SETTINGS_FILE="/etc/SFSit_MST.conf.sh"
test -s "/root/SFSit_MST.conf.sh" && SETTINGS_FILE="/root/SFSit_MST.conf.sh"
if [ -s "$SETTINGS_FILE" ]; then
	HOST_EMAIL="$(sh "$SETTINGS_FILE" HOST_EMAIL)"
	ADMIN_EMAIL="$(sh "$SETTINGS_FILE" ADMIN_EMAIL)"
fi

if [ "x$1" != "x" ]; then
	NOMAIL="$(echo $1 | tr '[:lower:]' '[:upper:]')"
	if [ "x$NOMAIL" = "x-H" -o "x$NOMAIL" = "HELP" ]; then
		echo "$SYNTAX"
		exit 1;
	fi
	if [ "x$NOMAIL" = "xNOMAIL" ]; then
		ADMIN_EMAIL=""
	fi
fi

##
## INIT THE TRUE SCRIPT
##
EXECTIMEMARK="$(date "+%Y%m%d%H%M")"
MFILE="certbot_renew_log_$EXECTIMEMARK"
mkdir /tmp/$MFILE
certbot renew 2>&1 > /tmp/$MFILE/mailbody.txt
printf "\n\n\n==== LOG ===\n"  >> /tmp/$MFILE/mailbody.txt
cat '/var/log/letsencrypt/letsencrypt.log' >> /tmp/$MFILE/mailbody.txt
( echo "$HOST_EMAIL: CERTBOT RENEW LOG $( date )" > "/tmp/$MFILE/head.txt" ) || exit_with_error "ERROR: CANNOT CREATE HEADER FILE '/tmp/$MFILE/head.txt'"
if [  "x$ADMIN_EMAIL" != "x" -a -x $MTA ]; then
	( mst_sendmail "$HOST_EMAIL" "$ADMIN_EMAIL" "/tmp/$MFILE/head.txt" "/tmp/$MFILE/mailbody.txt" ) || exit_with_error "ERROR: sending $ADMIN_EMAIL" 
else
	cat "/tmp/$MFILE/mailbody.txt" || exit_with_error "ERROR: CANNOT CAT FILES  '/tmp/$MFILE'"
fi
rm -R "/tmp/$MFILE" 
cd "$PWD"
exit 0
