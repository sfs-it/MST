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

BASESCRIPT="$(basename $0)"
DIRSCRIPT="$(dirname $0)"
if [ -s "$DIRSCRIPT/SFSit_MST.conf.sh" ]; then
	. "$( readlink -f "$DIRSCRIPT/SFSit_MST.conf.sh" )"
fi
SYNTAX="$BASESCRIPT [nomail] [days] [VHOST]"
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
	VHOSTS_DIR="$(sh "$SETTINGS_FILE" VHOSTS_DIR)"
	HTTPDOCS_DIR="$(sh "$SETTINGS_FILE" HTTPDOCS_DIR)"
	HTTPLOGS_DIR="$(sh "$SETTINGS_FILE" HTTPLOGS_DIR)"
	LORG_DIR="$(sh "$SETTINGS_FILE" LORG_DIR)"
	LORG_OPT="$(sh "$SETTINGS_FILE" LORG_OPT)"
	LORG_SPLITTED="$(sh "$SETTINGS_FILE" LORG_SPLITTED)"
fi
if [ "x$LORG_DIR" = "x" ]; then
	exit_with_error "LORG_DIR MUST BE SETTED ON SYSTEM PREFERENCES"
fi

if [ "x$LORG_SPLITTED" = "x" ]; then
	LORG_SPLITTED=1
else
	LORG_SPLITTED="$(echo $LORG_SPLITTED | tr '[:upper:]' '[:lower:]')";
	if [ "$LORG_SPLITTED" = "1" -o "$LORG_SPLITTED" = "true" ]; then
		LORG_SPLITTED=1
	else
		LORG_SPLITTED=0
	fi
fi
if [ "x$LORG_SAVE_REPORT_ON_HTTPDOC_SLOGS" = "x" ]; then
	LORG_SAVE_REPORT_ON_HTTPDOC_SLOGS=1
else
	LORG_SAVE_REPORT_ON_HTTPDOC_SLOGS="$(echo $LORG_SAVE_REPORT_ON_HTTPDOC_SLOGS | tr '[:upper:]' '[:lower:]')";
	if [ "$LORG_SAVE_REPORT_ON_HTTPDOC_SLOGS" = "1" -o "$LORG_SAVE_REPORT_ON_HTTPDOC_SLOGS" = "true" ]; then
		LORG_SAVE_REPORT_ON_HTTPDOC_SLOGS=1
	else
		LORG_SAVE_REPORT_ON_HTTPDOC_SLOGS=0
	fi
fi
if [ "x$LORG_ATTACH_REPORT" = "x" ]; then
	LORG_ATTACH_REPORT=1
else
	LORG_ATTACH_REPORT="$(echo $LORG_ATTACH_REPORT | tr '[:upper:]' '[:lower:]')";
	if [ "$LORG_ATTACH_REPORT" = "1" -o "$LORG_ATTACH_REPORT" = "true" ]; then
		LORG_ATTACH_REPORT=1
	else
		LORG_ATTACH_REPORT=0
	fi
fi
if [ "x$LORG_OPT" = "x" ]; then
	LORG_OPT=' -i combined -o html -d phpids -d chars -d dnsbl  -a all -c all -b all -t 10 -v 2 -h -g -p'
fi
LORG_CHECKED_phpids=0
LORG_CHECKED_dnsbl=0
LORG_CHECKED_chars=0
LORG_CHECKED=''
test "x$(echo "$LORG_OPT" | grep -e '-d phpids' )" != 'x' && LORG_CHECKED_phpids=1 && LORG_CHECKED="-phpids"
test "x$(echo "$LORG_OPT" | grep -e '-d dnsbl' )" != 'x'  && LORG_CHECKED_dnsbl=1 && LORG_CHECKED="$LORG_CHECKED-dnsbl"
test "x$(echo "$LORG_OPT" | grep -e '-d chars' )" != 'x'  && LORG_CHECKED_chars=1 && LORG_CHECKED="$LORG_CHECKED-chars"
if [ $LORG_SPLITTED = 1 ]; then
	LORG_OPT=$(echo "$LORG_OPT" | sed -e 's/-d phpids//' -e 's/-d dnsbl//' -e 's/-d chars//')
fi

VHOST="*"
HOST_EMAIL="$(cat /etc/mailname)"

if [ "x$1" != "x" ]; then
	NOMAIL="$(echo $1 | tr '[:lower:]' '[:upper:]')"
	if [ "x$NOMAIL" = "x-H" -o "x$NOMAIL" = "HELP" ]; then
		echo "$SYNTAX"
		exit 1;
	fi
	if [ "x$NOMAIL" = "xNOMAIL" ]; then
		ADMIN_EMAIL=""
		if [ "x$2" != "x" ]; then
			[ "x$2" != "x" ] && VHOST="$2"
		fi
		
	else
		if [ "x$1" != "x" ]; then
			VHOST="$1"
		fi
	fi
fi

##
## INIT THE TRUE SCRIPT
##
EXECTIMEMARK="$(date "+%Y%m%d%H%M")"
if [ "x$VHOST" = 'x*' ]; then
	MFILE="mfiles_logs_allvhosts_$EXECTIMEMARK"
else
	MFILE="mfiles_logs_$VHOST_$EXECTIMEMARK"
fi
STARTTIMEMARK="$(date -d "30 minutes ago" "+%Y%m%d%H%M")"
mkdir "/tmp/$MFILE"
( touch  -t "$STARTTIMEMARK"  "/tmp/$MFILE/files.list" ) || exit_with_error "ERROR: CANNOT CREATE MARKER/LS FILE '/tmp/$MFILE/files.list'"
( echo "$HOST_EMAIL: ANALYSIS APACHE LOGFILES $( date )" > "/tmp/$MFILE/head.txt" ) || exit_with_error "ERROR: CANNOT CREATE HEADER FILE '/tmp/$MFILE/head.txt'"
( touch  -t "$STARTTIMEMARK" "/tmp/$MFILE/head.txt" ) || exit_with_error "ERROR: CANNOT FIX HEADER FILE TIME '/tmp/$MFILE/head.txt'"
if cd "$VHOSTS_DIR"; then
	for VHOST_ACCOUNTFILE in $(ls -1 $VHOSTS_DIR/$VHOST/account.txt); do
		VHOST_PATH="$(echo $VHOST_ACCOUNTFILE | sed -E 's/\/account.txt$//')"
		test -d  $VHOST_PATH/$HTTPLOGS_DIR || exit_with_error "ERROR: on access '$VHOST_PATH/$HTTPLOGS_DIR'"
		find $VHOST_PATH/$HTTPLOGS_DIR -newer "/tmp/$MFILE/head.txt" \( -name "access.log.1" -o -name "error.log.1" \) -ls  | sed "s#^.*$VHOST_PATH#$VHOST:$VHOST_PATH#" > "$VHOST_PATH/$MFILE-files.list"
		if [ -s "$VHOST_PATH/$MFILE-files.list" ]; then 
			VHOST_ADMIN_EMAIL="$(cat` "$VHOST_ACCOUNTFILE" | grep 'ADMIN_EMAIL:' | sed 's/^ADMIN_EMAIL:\s*//')"
                        VHOST_HOST_EMAIL="$(cat` "$VHOST_ACCOUNTFILE" | grep 'VHOST_EMAIL:' | sed 's/^VHOST_EMAIL:\s*//')"
                        if [ [ [ "x$VHOST_HOST_EMAIL" != "x"  -a "x$VHOST_HOST_EMAIL" != "x$HOST_EMAIL" ] -o \
                               [ "x$VHOST_ADMIN_EMAIL" != "x" -a "x$VHOST_ADMIN_EMAIL" != "x$ADMIN_EMAIL" ]  \
                             ] -a -x $MTA ]; then
                                test "x$VHOST_HOST_EMAIL" == "x" && VHOST_HOST_EMAIL="$HOST_EMAIL"
                                test "x$VHOST_ADMIN_EMAIL" == "x" && VHOST_ADMIN_EMAIL="$ADMIN_EMAIL"
				( echo "$HOST_EMAIL: vhost '$VHOST_HOSTNAME' MODIFIED FILES FROM $STARTDATE TO $ENDDATE" > "/tmp/$MFILE/$VHOST_HOSTNAME.head" ) || exit_with_error "ERROR: CANNOT CREATE SINGLE VHOST FILE '/tmp/$MFILE/$VHOST_HOSTNAME.head'"
				( cat "$VHOST_PATH/$MFILE-files.list" | sed "s#^/#$VHOST_HOSTNAME /#" > "/tmp/$MFILE/$VHOST_HOSTNAME.ls" ) || exit_with_error "ERROR: CANNOT CREATE SINGLE VHOST FILE '/tmp/$MFILE/$VHOST_HOSTNAME.ls'"
				( cat "/tmp/$MFILE/$VHOST_HOSTNAME.head" "/tmp/$MFILE/$VHOST_HOSTNAME.ls" > "/tmp/$MFILE/$VHOST_HOSTNAME.log" ) || exit_with_error "ERROR: CANNOT CREATE SINGLE VHOST FILE '/tmp/$MFILE/$VHOST_HOSTNAME.log'"
				( mst_sendmail "$VHOST_HOST_EMAIL" "$VHOST_ADMIN_EMAIL" "/tmp/$MFILE/$VHOST_HOSTNAME.head" "/tmp/$MFILE/$VHOST_HOSTNAME.log" ) || exit_with_error "ERROR: CANNOT SEND EMAIL TO SINGLE VHOST '$VHOST_ADMIN_EMAIL'"
				( rm "/tmp/$MFILE/$VHOST_HOSTNAME.head" "/tmp/$MFILE/$VHOST_HOSTNAME.ls" "$VHOST_PATH/$MFILE-files.list" ) || exit_with_error "ERROR: CANNOT REMOVE FILES  '/tmp/$MFILE/$VHOST_HOSTNAME.head' '/tmp/$MFILE/$VHOST_HOSTNAME.ls' '$VHOST_PATH/$MFILE-files.list' '/tmp/$MFILE/$VHOST_HOSTNAME.mailbody'"
			fi
		else
			rm "$VHOST_PATH/$MFILE-files.list" || exit_with_error "ERROR: CANNOT DELETE VOID FILE '$VHOST_PATH/$MFILE-files.list'"
		fi
	done
	( find "$VHOSTS_DIR"  -maxdepth 2 -name "$MFILE-files.list" -exec cat {} \; -exec rm {} \;  > "/tmp/$MFILE/files.list" ) || exit_with_error "ERROR: building FILE '/tmp/$MFILE/files.list' for report"
	if [ -s "/tmp/$MFILE/files.list" ]; then
		( cat "/tmp/$MFILE/head.txt" >  "/tmp/$MFILE/mailbody.txt" ) || exit_with_error "ERROR: building '/tmp/$MFILE/mailbody.txt'"
		touch "/tmp/$MFILE/attachments.list" ||  exit_with_error "ERROR: CANNOT CREATE '/tmp/$MFILE/attachments_list'" 
		cd "$LORG_DIR"
		for VHOST in $(cat "/tmp/$MFILE/files.list" | grep 'access.log.1' | awk -F ':' '{print($1);}' | uniq); do
			if [ "x$VHOST" = "x" ]; then
				continue;
			fi
			mkdir "/tmp/$MFILE/$VHOST"
			VHOST_PATH="$VHOSTS_DIR/$VHOST"
			LOG_FILE="$VHOST_PATH/$HTTPLOGS_DIR/access.log.1"
			LOG_FILE_DATE="$(find $LOG_FILE -maxdepth 0 -printf "%TY%Tm%Td-%TH%TM")"
			echo "$VHOST: ANALYSIS APACHE LOGFILES access.log $( date -r "LOG_FILE")" >> "/tmp/$MFILE/mailbody.txt"
			if [ $LORG_SPLITTED -eq 1 ]; then
				for lorg_type in 'phpids' 'dnsbl' 'chars'; do
					eval "LORG_CHECKED_TMP=\$LORG_CHECKED_$lorg_type"
					if [ $LORG_CHECKED_TMP -eq 1 ]; then 
						REPORT_FILE="report-$LOG_FILE_DATE-$lorg_type.html"
						./lorg $LORG_OPT -d $lorg_type \
							"$LOG_FILE" \
							"/tmp/$MFILE/$VHOST/$REPORT_FILE" 2>&1 > "/tmp/$MFILE/$VHOST/lorg-$lorg_type.log"
						echo "\n/tmp/$MFILE/$VHOST/lorg-$lorg_type.log" >> "/tmp/$MFILE/attachments.list"
						[ $LORG_ATTACH_REPORT -eq 1 ] && echo "\n/tmp/$MFILE/$VHOST/$REPORT_FILE" >> "/tmp/$MFILE/attachments.list"
						if [ $LORG_SAVE_REPORT_ON_HTTPDOC_SLOGS -eq 1 ]; then
							cp "/tmp/$MFILE/$VHOST/$REPORT_FILE" "$VHOST_PATH/$HTTPDOCS_DIR/logs/$REPORT_FILE"
							echo "LORG $lorg_type saved on: http://$VHOST/logs/$REPORT_FILE" >> "/tmp/$MFILE/mailbody.txt"
						fi
					fi
				done
			else
				REPORT_FILE="report-$LOG_FILE_DATE-$LORG_CHECKED.html"
				./lorg $LORG_OPT \
					"$LOG_FILE" \
					"/tmp/$MFILE/$VHOST/$REPORT_FILE" 2>&1 > "/tmp/$MFILE/$VHOST/lorg-$LORG_CHECKED.log"
				echo "\n/tmp/$MFILE/$VHOST/lorg-$LORG_CHECKED.log" >> "/tmp/$MFILE/attachments.list"
				[ $LORG_ATTACH_REPORT -eq 1 ] && echo "\n/tmp/$MFILE/$VHOST/$REPORT_FILE" >> "/tmp/$MFILE/attachments.list"
				if [ $LORG_SAVE_REPORT_ON_HTTPDOC_SLOGS -eq 1 ]; then
					cp "/tmp/$MFILE/$VHOST/$REPORT_FILE" "$VHOST_PATH/$HTTPDOCS_DIR/logs/$REPORT_FILE"
					echo "LORG combined $LORG_CHECKED saved on: http://$VHOST/logs/$REPORT_FILE" >> "/tmp/$MFILE/mailbody.txt"
				fi
			fi
		done
		for VHOST in $(cat "/tmp/$MFILE/files.list" | grep 'error.log.1' | awk -F ':' '{print($1);}' | uniq); do
			if [ "x$VHOST" = "x" ]; then
				continue;
			fi
			VHOST_PATH="$VHOSTS_DIR/$VHOST"
			LOG_FILE="$VHOST_PATH/$HTTPLOGS_DIR/error.log.1"
			echo "$VHOST: ATTACH APACHE LOGFILES error.log $( date -r "LOG_FILE")" >> "/tmp/$MFILE/mailbody.txt"
			if [ -s "$LOG_FILE" ]; then
				cp "$LOG_FILE" "/tmp/$MFILE/$VHOST/error.log"
				echo "\n"/tmp/$MFILE/$VHOST/error.log"" >> "/tmp/$MFILE/attachments.list"
			fi
		done
		if [  "x$ADMIN_EMAIL" != "x" -a -x $MTA ]; then
			( mst_sendmail "$HOST_EMAIL" "$ADMIN_EMAIL" "/tmp/$MFILE/head.txt" "/tmp/$MFILE/mailbody.txt" "/tmp/$MFILE/attachments.list" ) || exit_with_error "ERROR: sending $ADMIN_EMAIL" 
		else
			cat "/tmp/$MFILE/head.txt" "/tmp/$MFILE/files.list" || exit_with_error "ERROR: CANNOT CAT FILES  '/tmp/$MFILE/head.txt' /tmp/$MFILE/files.list'"
		fi
	fi
fi
rm -R "/tmp/$MFILE" 
cd "$PWD"
exit 0
