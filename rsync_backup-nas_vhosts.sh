#!/bin/sh
#
# SFS.it Maintenance Server Tools 
# BSD style KISS scripts
#
# RSYNC VHOSTS TO NAS_DIS
#
# Written by Agostino Zanutto (agostino@sfs.it) for SFS.it MST
#

#SYNTAX rsync_backup-nas_vhosts [CLEANLOCK]
SYNTAX="$BASESCRIPT [CLEANLOCK] [TEST]"

BASESCRIPT="$(basename $0)"
DIRSCRIPT="$(realpath $(dirname $0))"

LOCKFILE='/tmp/rsync_backup-nas_vhosts.lock'
VERBOSE=''	
TEST=''
if [ "x$1" != "x" ]; then
	P1="$(echo $1 | tr '[:lower:]' '[:upper:]')"
	if [ "x$P1" = "x-H" -o "x$P1" = "HELP" ]; then
		echo "$SYNTAX"
		exit 1;
	elif [ "x$P1" = "xCLEANLOCK" ]; then
		if [ -e  "$LOCKFILE" ]; then
			rm "$LOCKFILE"
			echo "LOCKFILE '$LOCKFILE' REMOVED"
			exit
		fi
	elif [ "x$P1" = "xTEST" ]; then
		TEST="TEST"	
	elif [ "x$P1" = "x-V" -o "x$P1" = "xVERBOSE" ]; then
		VERBOSE="VERBOSE"	
	fi
fi
if  [ "x$2" != "x" ]; then
	P2="$(echo $2 | tr '[:lower:]' '[:upper:]')"
	if [ "x$P2" = "xCLEANLOCK" ]; then
		if [ -e "$LOCKFILE" ]; then
			rm "$LOCKFILE"
			echo "LOCKFILE '$LOCKFILE' REMOVED"
			exit
		fi
	elif [ "x$P2" = "xTEST" ]; then
		TEST="TEST"	
	elif [ "x$P2" = "x-V" -o "x$P2" = "xVERBOSE" ]; then
		VERBOSE="VERBOSE"
	fi
fi
if  [ "x$3" != "x" ]; then
	P3="$(echo $3 | tr '[:lower:]' '[:upper:]')"
	if [ "x$P3" = "xCLEANLOCK" ]; then
		if [ -e "$LOCKFILE" ]; then
			rm "$LOCKFILE"
			echo "LOCKFILE '$LOCKFILE' REMOVED"
			exit
		fi
	elif [ "x$P3" = "xTEST" ]; then
		TEST="TEST"	
	elif [ "x$P3" = "x-V" -o "x$P3" = "xVERBOSE" ]; then
		VERBOSE="VERBOSE"
	fi
fi

if [ -e  "$LOCKFILE" ]; then
	echo "RSYNCBACKUP - LOCKFILE '$LOCKFILE' PRESENT QUIT"
	exit
fi
PWD=$(pwd)
##
## INIT PARAMETERS
##
umask 022

SETTINGS_FILE="/etc/SFSit_MST.conf.sh"
test -s "/root/SFSit_MST.conf.sh" && SETTINGS_FILE="/root/SFSit_MST.conf.sh"
if [ -s "$SETTINGS_FILE" ]; then
	VHOSTS_DIR="$(sh "$SETTINGS_FILE" VHOSTS_DIR)"
	NAS_DIR="$(sh "$SETTINGS_FILE" NAS_DIR)"
else
	echo "NO CONFIG SET COPY SFSit_MST.conf.sh.orig /etc/SFSit_MST.conf.sh or /root/SFSit_MST.conf.sh and set local variables"
	exit 1
fi
if [ "x$NAS_DIR" = "x" ]; then
	echo "RSYNCBACKUP - EXIT NO NAS_DIR DEFINED"
	exit
fi


##
## INIT THE TRUE SCRIPT
##
#RSYNC_CMD="rsync --links --recursive --perms --xattrs --owner --group --times --delete --exclude *.log.*.gz --verbose"
RSYNC_CMD="rsync --links --recursive --perms --owner --group --times --delete --exclude *.log.*.gz --exclude .recycle --exclude lost+found"
if [ $TEST = 'TEST' ]; then
	RSYNC_CMD="$RSYNC_CMD --dry-run"
fi
if [ $VERBOSE = 'VERBOSE' ]; then
	RSYNC_CMD="$RSYNC_CMD  --verbose"
fi
touch "$LOCKFILE"
if cd "$VHOSTS_DIR"; then
	for VHOST in $(ls -1 $VHOSTS_DIR); do
		echo "***"
		echo "*** VHOST: $VHOST ***"
		echo "***"
		if [ "x$VHOST" = "xgDrive" -o "x$VHOST" = "xlost+found"  -o "x$VHOST" = ".zfs" ]; then
			# DIR SKIPPED
		elif [ -d "$VHOSTS_DIR/$VHOST" -a -d "$NAS_DIR/$VHOST/" ]; then
			cd "$VHOSTS_DIR/$VHOST"
			if [ -f "account.txt" ]; then 
				USER="$(cat "account.txt" | grep '^USER:' | sed -E 's/^USER:\s*//' | sed 's/^[[:blank:]]*//g')"
				MYSQL_PWD="$(cat "account.txt" | grep '^PWD_MYSQL:' | sed 's/^PWD_MYSQL:\s*//' | sed 's/^[[:blank:]]*//g')"
				echo "BACKUP DB: \"$USER\" TO dump-$USER.sql"
				mysqldump --opt "$USER" > "dump-$USER.sql" -u "$USER" --password="$MYSQL_PWD"
			fi 
			echo "SYNC \"$VHOSTS_DIR/$VHOST/\" to \"$NAS_DIR/$VHOST/\""
			$RSYNC_CMD "$VHOSTS_DIR/$VHOST/" "$NAS_DIR/$VHOST/"
			echo "END OF SYNC"
		else
			echo "SYNC of \"$VHOSTS_DIR/$VHOST/\" SKIPPED"
		fi
	done
fi
rm "$LOCKFILE"
cd "$PWD"
exit 0
