#!/bin/sh
#
# SFS.it Maintenance Server Tools 
# BSD style KISS scripts
#
# FILE MODIFIED CHECKER SINCE N DAYS
#
# Written by Agostino Zanutto (agostino@sfs.it) for SFS.it MST
#

#SYNTAX files-chk.sh [nomail] [days][VHOST]
SYNTAX="$BASESCRIPT [nomail] [days] [VHOST]"

BASESCRIPT="$(basename $0)"
DIRSCRIPT="$(dirname $0)"
. $DIRSCRIPT/mst_sendmail.sh


PWD=$(pwd)
. $DIRSCRIPT/mst_sendmail.sh
##
## INIT PARAMETERS
##

umask 022

SETTINGS_FILE="/etc/SFSit_MST.conf.sh"
test -s "/root/SFSit_MST.conf.sh" && SETTINGS_FILE="/root/SFSit_MST.conf.sh"
if [ -s "$SETTINGS_FILE" ]; then
	HOST_EMAIL="$(sh "$SETTINGS_FILE" HOST_EMAIL)"
	ADMIN_EMAIL="$(sh "$SETTINGS_FILE" ADMIN_EMAIL)"
	VHOSTS_DIR="$(sh "$SETTINGS_FILE" VHOSTS_DIR)"
	HTTPDOCS_DIR="$(sh "$SETTINGS_FILE" HTTPDOCS_DIR)"
else
	echo "NO CONFIG SET COPY SFSit_MST.conf.sh.orig /etc/SFSit_MST.conf.sh or /root/SFSit_MST.conf.sh and set local variables"
	exit 1
fi

NDAYS=1
VHOST="*"

if [ "x$1" != "x" ]; then
	NOMAIL="$(echo $1 | tr '[:lower:]' '[:upper:]')"
	if [ "x$NOMAIL" = "x-H" -o "x$NOMAIL" = "HELP" ]; then
		echo "$SYNTAX"
		exit 1;
	fi
	if [ "x$NOMAIL" = "xNOMAIL" ]; then
		ADMIN_EMAIL=""
		if [ "x$2" != "x" -a "x$(echo $2 | sed -e 's/[^0-9]*//g')" = "x$2" ]; then
			[ "x$2" != "x" ] && NDAYS="$2"
			[ "x$3" != "x" ] && VHOST="$3"
		else
			[ "x$2" != "x" ] && VHOST="$2"
		fi
	else
		if [ "x$1" != "x" -a "x$(echo $1 | sed -e 's/[^0-9]*//g')" = "x$1" ]; then
			NDAYS="$1"
			[ "x$2" != "x" ] && VHOST="$2"
		else
			[ "x$1" != "x" ] && VHOST="$1"
		fi
	fi
fi

##
## INIT THE TRUE SCRIPT
##
if [ "x$(uname)" = 'xFreeBSD' ]; then
	STARTTIMEMARK="$(date -v-${NDAYS}d "+%Y%m%d%H%M")"
	ENDTIMEMARK="$(date "+%Y%m%d%H%M")"
else
	STARTTIMEMARK="$(date -d "$NDAYS day ago" "+%Y%m%d%H%M")"
	ENDTIMEMARK="$(date "+%Y%m%d%H%M")"
fi
MFILE="mfiles_$STARTTIMEMARK-$ENDTIMEMARK"
( touch -t "$STARTTIMEMARK" "/tmp/$MFILE.ls" ) || exit_with_error "ERROR: CANNOT CREATE MARKER/LS FILE '/tmp/$MFILE.ls'"
if [ "x$(uname)" = 'xFreeBSD' ]; then
	STARTDATE="$(date -v-${NDAYS}d "+%H:%M %d/%m/%Y")"
	ENDDATE="$(date "+%H:%M %d/%m/%Y")"
else
	STARTDATE="$(date -d "$NDAYS day ago" "+%H:%M %d/%m/%Y")"
	ENDDATE="$(date "+%H:%M %d/%m/%Y")"
fi
( echo "$HOST_EMAIL: MODIFIED FILES FROM $STARTDATE TO $ENDDATE" > "/tmp/$MFILE.head" ) || exit_with_error "ERROR: CANNOT CREATE HEADER FILE '/tmp/$MFILE.head'"
if cd "$VHOSTS_DIR"; then
	for VHOST_ACCOUNTFILE in $(ls -1 $VHOSTS_DIR/$VHOST/account.txt); do
		VHOST_PATH="$(echo $VHOST_ACCOUNTFILE | sed -E 's/\/account.txt$//')"
		test -d  $VHOST_PATH/$HTTPDOCS_DIR || exit_with_error "ERROR: on access '$VHOST_PATH/$HTTPDOCS_DIR'"
		find $VHOST_PATH/$HTTPDOCS_DIR -newer "/tmp/$MFILE.ls" -ls | sed "s#$VHOST_PATH/$HTTPDOCS_DIR/#  #" | grep -v "$VHOST_PATH/$HTTPDOCS_DIR"  > "$VHOST_PATH/$MFILE.ls"
		if [ -s "$VHOST_PATH/$MFILE.ls" ]; then 
			VHOST_HOSTNAME="$(echo "$VHOST_PATH" | sed "s#$VHOSTS_DIR/##")" 
			VHOST_ADMIN_EMAIL="$(cat "$VHOST_ACCOUNTFILE" | grep 'ADMIN_EMAIL:' | sed 's/^ADMIN_EMAIL:\s*//')"
			VHOST_HOST_EMAIL="$(cat "$VHOST_ACCOUNTFILE" | grep 'VHOST_EMAIL:' | sed 's/^VHOST_EMAIL:\s*//')"
			if [ "x$VHOST_HOST_EMAIL" != "x"  -a "x$VHOST_HOST_EMAIL" != "x$HOST_EMAIL" ] || \
			   [ "x$VHOST_ADMIN_EMAIL" != "x" -a "x$VHOST_ADMIN_EMAIL" != "x$ADMIN_EMAIL" ]; then
				test "x$VHOST_HOST_EMAIL" == "x" && VHOST_HOST_EMAIL="$HOST_EMAIL"
				test "x$VHOST_ADMIN_EMAIL" == "x" && VHOST_ADMIN_EMAIL="$ADMIN_EMAIL"
				( echo "$HOST_EMAIL: vhost '$VHOST_HOSTNAME' MODIFIED FILES FROM $STARTDATE TO $ENDDATE" > "/tmp/$MFILE-$VHOST_HOSTNAME.head" ) || exit_with_error "ERROR: CANNOT CREATE SINGLE VHOST FILE '/tmp/$MFILE-$VHOST_HOSTNAME.head'"
				( cat "$VHOST_PATH/$MFILE.ls" | sed "s#**$VHOSTS_DIR/#VHOST:#" > "/tmp/$MFILE-$VHOST_HOSTNAME.ls" ) || exit_with_error "ERROR: CANNOT CREATE SINGLE VHOST FILE '/tmp/$MFILE-$VHOST_HOSTNAME.ls'"
				( cat "/tmp/$MFILE-$VHOST_HOSTNAME.head" "/tmp/$MFILE-$VHOST_HOSTNAME.ls" > "/tmp/$MFILE-$VHOST_HOSTNAME.maillog" ) || exit_with_error "ERROR: CANNOT CREATE SINGLE VHOST FILE '/tmp/$MFILE-$VHOST_HOSTNAME.maillog'"
				( mst_sendmail "$VHOST_HOST_EMAIL" "$VHOST_ADMIN_EMAIL" "/tmp/$MFILE-$VHOST_HOSTNAME.head" "/tmp/$MFILE-$VHOST_HOSTNAME.maillog" ) || exit_with_error "ERROR: CANNOT SEND EMAIL TO SINGLE VHOST '$VHOST_ADMIN_EMAIL' FROM '$VHOST_HOST_EMAIL'"
				( rm "/tmp/$MFILE-$VHOST_HOSTNAME.head" "/tmp/$MFILE-$VHOST_HOSTNAME.ls" "$VHOST_PATH/$MFILE.ls" ) || exit_with_error "ERROR: CANNOT REMOVE FILES  '/tmp/$MFILE-$VHOST_HOSTNAME.head' '/tmp/$MFILE-$VHOST_HOSTNAME.ls' '$VHOST_PATH/$MFILE.ls' '/tmp/$MFILE-$VHOST_HOSTNAME.mailbody'"
			fi
		else
			rm "$VHOST_PATH/$MFILE.ls" || exit_with_error "ERROR: CANNOT DELETE VOID FILE '$VHOST_PATH/$MFILE.ls' FILE"
		fi
	done
	( find "$VHOSTS_DIR"  -maxdepth 2 -name "$MFILE.ls" -exec echo -n "**" \; -exec dirname {} \; -exec cat {} \; -exec rm {} \;  | sed "s#**$VHOSTS_DIR/#VHOST:#" > "/tmp/$MFILE.ls" ) || exit_with_error "ERROR: building FILE '/tmp/$MFILE.ls' for report"
	if [ -s "/tmp/$MFILE.ls" ]; then
		if [  "x$ADMIN_EMAIL" != "x" ]; then
			( cat "/tmp/$MFILE.head" "/tmp/$MFILE.ls" >  "/tmp/$MFILE.maillog" ) || exit_with_error "ERROR: building '/tmp/$MFILE.maillog'"
			( mst_sendmail "$HOST_EMAIL" "$ADMIN_EMAIL" "/tmp/$MFILE.head" "/tmp/$MFILE.maillog" ) || exit_with_error "ERROR: sending $ADMIN_EMAIL" 
		else
			cat "/tmp/$MFILE.head" "/tmp/$MFILE.ls" || exit_with_error "ERROR: CANNOT CAT FILES  '/tmp/$MFILE.head' /tmp/$MFILE.ls'"
		fi
	fi
fi
rm  "/tmp/$MFILE.head" "/tmp/$MFILE.ls" || exit_with_error "ERROR: CANNOT REMOVE FILES  '/tmp/$MFILE.head' /tmp/$MFILE.ls' '/tmp/$MFILE.mailbody'"
cd "$PWD"
exit 0
