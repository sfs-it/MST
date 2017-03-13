#!/bin/sh#
# SFS.it Maintenance Server Tools 
# BSD style KISS scripts
#
# CREATE VHOST WITH USER,HOMEDIR, DB etc etc etc
#
# Written by Agostino Zanutto (agostino@sfs.it) for SFS.it MST
#
# USAGE VHOST USER [PWD_FTP [PWD_MYSQL [ADMIN_EMAIL]]]
BASESCRIPT="$(basename $0)"
PATHSCRIPT="$(dirname $0)"
SYNTAX="$BASESCRIPT VHOST USER [PWD_FTP [PWD_MYSQL [HOST_EMAIL [ADMIN_EMAIL [GRIVE_EMAIL [GRIVE_DIR [GRIVE_SUBDIR_BACKUPS]]]]]]][ -ALIASES ... VHOSTNAME ... VHOSTNAME ]" 

SETTINGS_FILE="/etc/SFSit_MST.conf.sh"
test -s "/root/SFSit_MST.conf.sh" && SETTINGS_FILE="/root/SFSit_MST.conf.sh"
if [ -s "$SETTINGS_FILE" ]; then
        HOSTNAME="$(sh "$SETTINGS_FILE" HOSTNAME | tr '[:lower:]' '[:upper:]')"
        test "x$HOSTNAME" = "x" && HOSTNAME="$(hostname)"
        PUBLIC_IP="$(sh "$SETTINGS_FILE" PUBLIC_IP | tr '[:lower:]' '[:upper:]')"
        test "x$PUBLIC_IP" = "x" && PUBLIC_IP="NONE"
        VHOSTS_DIR="$(sh "$SETTINGS_FILE" VHOSTS_DIR)"
        HOST_EMAIL="$(sh "$SETTINGS_FILE" ADMIN_EMAIL)"
        ADMIN_EMAIL="$(sh "$SETTINGS_FILE" ADMIN_EMAIL)"
        GRIVE_ENABLED="$(sh "$SETTINGS_FILE" GRIVE_ENABLED | tr '[:lower:]' '[:upper:]')"
	if [ "x$GRIVE_ENABLED" = 'xYES' ]; then
		GRIVE_EMAIL="$(sh "$SETTINGS_FILE" GRIVE_EMAIL)"
		GRIVE_DIR="$(sh "$SETTINGS_FILE" GRIVE_DIR)"
		GRIVE_SUBDIR_BACKUPS="$(sh "$SETTINGS_FILE" GRIVE_SUBDIR_BACKUPS | sed -E 's;^(/*)(.*[^/])*(/*)$;\2;g')"
		[ 'x' = "$GRIVE_EMAIL" ] && GRIVE_EMAIL="$ADMIN_EMAIL"
		[ 'x' = "$GRIVE_DIR" ] && GRIVE_DIR="$VHOSTS_DIR/gDrive"
		[ 'x' = "$GRIVE_SUBDIR_BACKUPS" ] && GRIVE_SUBDIR_BACKUPS='backups'
	fi
        HTTPS_ENABLED="$(sh "$SETTINGS_FILE" HTTPS_ENABLED | tr '[:lower:]' '[:upper:]')"
        SAMBA_ENABLED="$(sh "$SETTINGS_FILE" SAMBA_ENABLED | tr '[:lower:]' '[:upper:]')"
        MYSQL_ENABLED="$(sh "$SETTINGS_FILE" MYSQL_ENABLED | tr '[:lower:]' '[:upper:]')"
        LOGROTATE_ENABLED="$(sh "$SETTINGS_FILE" LOGROTATE_ENABLED | tr '[:lower:]' '[:upper:]')"
else
	echo "NO CONFIG FOUND"
	exit 1
fi
PWD_SRC="$(pwd)"
cd $(dirname $0) 
exit_with_error(){
	test 'x' != "x$1" && echo "$1"
	cd "$PWD_SRC"
	exit 1
}
[ "x$1" = 'x' ] && exit_with_error "$SYNTAX: VHOST NEEDED"
VHOST="$1"
[ "x$1" = 'x' ] && exit_with_error "$SYNTAX: USER NEEDED"
USER="$2"
id $USER 2>&1 > /dev/null 
[ $? -eq 0 ] && exit_with_error "USER $USER ALREADY EXISTS"
param_aliases=3
while [ $param_aliases -le $# ]; do
	eval param='$'$param_aliases
	if [ "x$(echo $param | tr '[:lower:]' '[:upper:]')" = 'x-ALIASES' ]; then
		break
	fi
	param_aliases=$(($param_aliases + 1))
done
VHOST_ALIASES=''
if [ $param_aliases -lt $# ]; then
	n=$(($param_aliases + 1))
	echo "ALIASES START AT PARAM $n"
	while [ $n -le $# ]; do
		eval new_alias='${'$n'}'
		VHOST_ALIASES="$VHOST_ALIASES $new_alias"
		n=$(($n + 1))
	done;
else
	param_aliases=0	
fi
PWD_FTP="$3"
[ "x$3" = 'x' -o \( $param_aliases -ne 0 -a $param_aliases -le 3 \) ] && PWD_FTP=$(perl $PATHSCRIPT/subs/pwd_generator.pl 8)
PWD_MYSQL="$4"
[ "x$4" = 'x' -o \( $param_aliases -ne 0 -a $param_aliases -le 4 \) ] && PWD_MYSQL=$(perl $PATHSCRIPT/subs/pwd_generator.pl 16)
[ "x$5" != 'x' -a $param_aliases -gt 5 ] && ADMIN_EMAIL="$5"
[ "x$6" != 'x' -a $param_aliases -gt 6 ] && HOST_EMAIL="$6"
[ "x$7" != 'x' -a $param_aliases -gt 7 ] && GRIVE_EMAIL="$7"
[ "x$8" != 'x' -a $param_aliases -gt 8 ] && GRIVE_DIR="$8"
[ "x$9" != 'x' -a $param_aliases -gt 9 ] && GRIVE_SUBDIR_BACKUPS="$9"
DOMAIN="$(echo "$VHOST" | sed -E 's/([^\.]*\.)*([^\.]*\.[^\.]*)$/\2/')"
VHOST_SFS="$(echo "$VHOST" | sed -E 's/(\.[^\.]*)$//')"
echo "CREATE account.txt file"
sh ./subs/create-account.txt.sh "$VHOST" "$USER" "$PWD_FTP" "$PWD_MYSQL" "$HOST_EMAIL" "$ADMIN_EMAIL" || exit_with_error  "ERROR: CREATING account.txt"
echo "report 'account.txt' file created"
echo "CREATE '$USER' account"
sh ./subs/create-user.sh "$VHOST" || exit_with_error "ERROR: CREATING USER '$USER'"
echo "CREATE $VHOST in $VHOSTS_DIR of $HOSTNAME for $USER with ftp password '$PWD_FTP' and mysql password: '$PWD_MYSQL'"
sh ./subs/create-vhost.sh "$VHOST" $VHOST_ALIASES ||exit_with_error "ERROR: CREATING VHOST '$VHOST'"
echo "vhost '$VHOST' created"
if [ "x$MYSQL_ENABLED" = "xYES" ]; then
	echo "CREATE $VHOST DATABASE (named $USER)"
	sh ./subs/create-db.sh "$VHOST" || exit_with_error "ERROR: CREATING DB for user '$USER'"
else
	echo "** MYSQL is disabled, to enable add \"MYSQL_ENABLED='YES'\" to your $SETTINGS_FILE"
fi
if [ "x$GRIVE_ENABLED" = "xYES" ]; then
	echo "ADD GRIVE PARAMETERS TO account.txt"
	sh ./subs/grive-account.txt.sh "$VHOST" "$GRIVE_EMAIL" "$GRIVE_DIR" "$GRIVE_SUBDIR_BACKUPS" || exit_with_error "ERROR: UPDATING account.txt FOR GRIVE PARAMETERS"
else
	echo "** GRIVE is disabled, to enable add \"GRIVE_ENABLED='YES'\" to your $SETTINGS_FILE"
fi
if [ "x$SAMBA_ENABLED" = "xYES" ]; then
	echo "CREATE smb '$VHOST' SHARE"
	sh ./subs/create-smb-share.sh "$VHOST" || exit_with_error "ERROR: CREATING SMB SHARE FOR $VHOST"
else
	echo "** SAMBA is disabled, to enable add \"SAMBA_ENABLED='YES'\" to your $SETTINGS_FILE"
fi
if [ "x$LOGROTATE_ENABLED" = "xYES" ]; then
	echo "CREATE logrotate entry for '$VHOST'"
	sh ./subs/create-logrotate.sh "$VHOST" || exit_with_error "ERROR: CREATING LOG ROTATE FOR $VHOST"
else
	echo "** LOGROTATE is disabled, to enable add \"LOGROTATE_ENABLED='YES'\" to your $SETTINGS_FILE"
fi
if [ "x$HTTPS_ENABLED" = "xYES" ]; then
	sh ./subs/create-vhost:ssl.sh "$VHOST" $VHOST_ALIASES ||exit_with_error "ERROR: CREATING VHOST SSL '$VHOST'"
else
	echo "** HTTPS VHOST config is disabled, to enable add \"HTTPS_ENABLED='YES'\" to your $SETTINGS_FILE"
fi
echo "vhost ssl '$VHOST' created"
if [ "x$PUBLIC_IP" = "xNONE" ]; then
	echo "** PUBLIC_IP config is disabled, to enable add \"PUBLIC_IP='xxx.xxx.xxx.xxx'\" with your public ip to your $SETTINGS_FILE"
else
	sh ./subs/add-vhost-to-hosts.sh "$VHOST" $VHOST_ALIASES ||exit_with_error "ERROR: ADDING $VHOST and $VHOST_ALIASES to /etc/hosts"
fi
echo "SEND email to $ADMIN_EMAIL"
sh ./subs/create-sendmail.sh "$VHOST" || exit_with_error  "ERROR: SENDING REPORT"
echo "email to $ADMIN_EMAIL sent"
echo "--- WELL DONE: USER, VHOST, DB, SMB SHARE, REPORT, MAIL SENT---"
cd "$PWD_SRC" 
