#~/bin/sh
# SFS.it Maintenance Server Tools 
# BSD style KISS scripts
#
# BACKUP VHOST (files, db and vhost)
#
# Written by Agostino Zanutto (agostino@sfs.it) for SFS.it MST
#

#SYNTAX: backup.sh [[rsync|rsync-only]|[[diff-backup|diff] [db-only]]] [VHOST]
BASESCRIPT="$(basename $0)"
DIRSCRIPT="$(dirname $0)"
SYNTAX="$BASESCRIPT [NOMAIL] [VHOST]"

PWD_SRC="$(pwd)"
SETTINGS_FILE="/etc/SFSit_MST.conf.sh"
test -s "~/SFSit_MST.conf.sh" && SETTINGS_FILE="~/SFSit_MST.conf.sh"
if [ -s "$SETTINGS_FILE" ]; then
	. "$SETTINGS_FILE"
fi
. "$DIRSCRIPT/subs/common.sh"
. "$DIRSCRIPT/mst_sendmail.sh"

MAIL_HOSTNAME="$(cat /etc/mailname)"

if [ "x$1" == "x" ]; then
	exit_with_error "$SYNTAX"
else
	NOMAIL="$(echo $1 | tr '[:lower:]' '[:upper:]')"
	if [ "x$NOMAIL" = "x-H" -o "x$NOMAIL" = "HELP" ]; then
		exit_with_error "$SYNTAX"
	fi
	if [ "x$NOMAIL" = "xNOMAIL" ]; then
		ADMIN_EMAIL=""
		if [ "x$2" = "x" ]; then
			exit_with_error "$SYNTAX"
		else
			VHOST="$2"
		fi
	else
		VHOST="$1"
	fi
fi

if [ ! -e "$PWD_SRC/joomla.xml" ]; then
	exit_with_error "THIS SCRIPT MUST BE RUN INTO UPDATE PACKAGE DIR, NO joomla.xml present at $PWD_SRC"
fi

if cd "$VHOSTS_DIR"; then
	VHOST_ACCOUNTFILE="$VHOSTS_DIR/$VHOST/account.txt"
	if [ -e "$VHOST_ACCOUNTFILE" ]; then
		VHOST_MARKFILE="/tmp/mst_joomla_update-$VHOST-$(date "+%Y%m%d%H%M").log";
		VHOST_PATH="$(echo $VHOST_ACCOUNTFILE | sed -E 's/\/account.txt$//')"
		VHOST_HOSTNAME="$(echo "$VHOST_PATH" | sed "s#$VHOSTS_DIR/##")"
		USER="$(cat $VHOST_ACCOUNTFILE | grep '^USER:' | sed 's/^USER:\s*//')"
		chown -R $USER:$WWW_GROUP $PWD_SRC
		VERSION="$(cat "$PWD_SRC/joomla.xml" | grep '<version>' | sed -e 's/\s*<version>\s*//' -e 's/\s*<\/version>//')"
		SUBJECT="UPDATE JOOMLA SITE $VHOST TO VERSION $VERSION";
		LIST=$(find $PWD_SRC/* -maxdepth 0 \(  \( -type d -a ! -name . \) -o \( -name "*.php" \) \) -print)
		cp -rvpR $LIST $VHOSTS_DIR/$VHOST/$HTTPDOCS_DIR 1>&2 >> "$VHOST_MARKFILE"
		if [ $? -eq 1 ]; then
			exit_with_error "ERROR: THERE WAS A ERROR ON COPY '$PWD_SRC' to '$VHOST'"
		fi
		( echo "UPDATED FILES:" && ( cat "$VHOST_MARKFILE" | sed -e "s#.*$VHOST/$HTTPDOCS_DIR/##" -e "s#'\$##" ) ) > "$VHOST_MARKFILE-2"
		mv "$VHOST_MARKFILE-2" "$VHOST_MARKFILE"
		if [ "x$ADMIN_EMAIL" = "x" -o ! -x $MTA ]; then
			echo "$SUBJECT"
			cat "$VHOST_MARKFILE"
		elif [ "x$VHOST_EMAIL" != "x" -a "x$VHOST_EMAIL" != "x$ADMIN_EMAIL" ]; then
			( mst_sendmail "$VHOST_EMAIL" "$ADMIN_EMAIL" "$SUBJECT" "$VHOST_MARKFILE" ) || exit_with_error "ERROR: CANNOT SEND EMAIL TO SINGLE VHOST '$VHOST_EMAIL'"
		else
			( mst_sendmail "$ADMIN_EMAIL" "$ADMIN_EMAIL" "$SUBJECT" "$VHOST_MARKFILE" ) || exit_with_error "ERROR: CANNOT SEND EMAIL '$ADMIN_EMAIL'"
		fi
		rm "$VHOST_MARKFILE"
	else
		exit_with_error "ERROR: CANNOT OPEN $VHOSTS_DIR/$VHOST/account.txt"
	fi
else
	exit_with_error "ERROR: CANNOT OPEN $VHOSTS_DIR"
fi
cd "$PWD_SRC"
exit 0
