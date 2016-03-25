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
SYNTAX="$0 [[rsync|rsync-only]|[[diff-backup|diff] [db-only]]] [VHOST]"

PWD_SRC="$(pwd)"
SETTINGS_FILE="/etc/SFSit_MST.conf.sh"
test -s "~/SFSit_MST.conf.sh" && SETTINGS_FILE="~/SFSit_MST.conf.sh"
if [ -s "$SETTINGS_FILE" ]; then
	VHOSTS_DIR="$(sh "$SETTINGS_FILE" VHOSTS_DIR)"
	WWW_GROUP="$(sh "$SETTINGS_FILE" WWW_GROUP)"
	HTTPDOCS_DIR="$(sh "$SETTINGS_FILE" HTTPDOCS_DIR)"
	ADMIN_EMAIL="$(sh "$SETTINGS_FILE" ADMIN_EMAIL)"
	HOST_EMAIL="$(sh "$SETTINGS_FILE" HOST_EMAIL)"
	APACHE_CONF="$(sh "$SETTINGS_FILE" APACHE_CONF)"
	[ "x$APACHE_CONF" = "x" ] && APACHE_CONF='SAVE'
	SAMBA_CONF="$(sh "$SETTINGS_FILE" SAMBA_CONF)"
	[ "x$SAMBA_CONF" = "x" ] && SAMBA_CONF='SAVE'
	GRIVE_EMAIL="$(sh "$SETTINGS_FILE" GRIVE_EMAIL)"
	GRIVE_DIR="$(sh "$SETTINGS_FILE" GRIVE_DIR)"
	GRIVE_SUBDIR_BACKUPS="$( sh "$SETTINGS_FILE" GRIVE_SUBDIR_BACKUPS | sed -E 's;^(/*)(.*[^/])*(/*)$;\2;g' )"
	[ "x$GRIVE_DIR" = "x" ] &&  GRIVE_DIR="$VHOSTS_DIR/gDrive"
	[ "x$GRIVE_SUBDIR_BACKUPS" = "x" ] &&  GRIVE_SUBDIR_BACKUPS="backups"
	[ "x$GRIVE_DIR" != "x" -a ! -e "$GRIVE_DIR" ] && \
	( 	mkdir -p "$GRIVE_DIR" && \
		chgrp "$WWW_GROUP" "$GRIVE_DIR" )
	GRIVE_SUBDIR_RSYNC="$( sh "$SETTINGS_FILE" GRIVE_SUBDIR_RSYNC | sed -E 's;^(/*)(.*[^/])*(/*)$;\2;g' )"
	[ "x$GRIVE_SUBDIR_RSYNC" = "x" ] &&  GRIVE_SUBDIR_RSYNC="rsync"
fi

exit_with_error(){
	test 'x' != "x$1" && echo "$1"
	cd "$PWD_SRC"
	exit 1
}

VHOST="*"
FIND_OPT_DIFF_BACKUP=""
TAR_OPT_DIFF_BACKUP=""
DIFF_BACKUP="$(echo $1 | tr '[:lower:]' '[:upper:]')"
RSYNC_ONLY=""
TIMEMARK="$(date "+%Y%m%d%H%M")"
FILE_TIMEMARK=''
START_TIMEMARK=''
if [ "x$DIFF_BACKUP" = "xRSYNC" -o  "x$DIFF_BACKUP" = "xRSYNC-ONLY" ]; then
        RSYNC_ONLY="YES"
        [ "x$2" != "x" ] && VHOST="$2"
else
        DIFF_NDAYS="$(echo $1 | sed -e 's/[^0-9]*//g')"
	test "x$DIFF_NDAYS" = "x$1" || DIFF_NDAYS=''
        if [ "x$DIFF_BACKUP" = "xDIFF-BACKUP" -o "x$DIFF_BACKUP" = "xDIFF" -o "x$DIFF_NDAYS" != "x" ]; then
                if [ "x$DIFF_NDAYS" != "x" ]; then
					DIFF_BACKUP='DATE'
                    START_TIMEMARK="$(date -d "$DIFF_NDAYS day ago" "+%Y%m%d%H%M")"
					FILE_TIMEMARK="/tmp/timemarkfile-$START_TIMEMARK"
					touch -t "$START_TIMEMARK" "$FILE_TIMEMARK"
				else
					DIFF_BACKUP='FILE'
				fi
                if [ "x$2" = "x" ]; then
                        DB_ONLY=''
                else
                        DB_ONLY="$(echo $2 | tr '[:lower:]' '[:upper:]')"
                        if [ "x$DB_ONLY" = "xDB-ONLY" ]; then
                                [ "x$3" != "x" ] && VHOST="$3"
                        else
                                DB_ONLY=''
                                VHOST="$2";
                        fi
                fi
        else
                DIFF_BACKUP=''
                DB_ONLY="$(echo $1 | tr '[:lower:]' '[:upper:]')"
                if [ "x$DB_ONLY" = "xDB-ONLY" ]; then
                        [ "x$2" != "x" ] && VHOST="$2"
                else
                        [ "x$1" != "x" ] && VHOST="$1"
                        DB_ONLY=''
                fi
        fi
fi

if cd "$VHOSTS_DIR"; then
	for VHOST_ACCOUNTFILE in $(ls -1 $VHOSTS_DIR/$VHOST/account.txt); do
		VHOST_PATH="$(echo $VHOST_ACCOUNTFILE | sed -E 's/\/account.txt$//')"
		VHOST_HOSTNAME="$(echo "$VHOST_PATH" | sed "s#$VHOSTS_DIR/##")"
		TMP_BACKUP="$VHOST_PATH/tmpdir_backup_$TIMEMARK"
		[ "x$RSYNC_ONLY" = "x" ] && \
			mkdir -p "$TMP_BACKUP"
		USER="$(cat $VHOST_ACCOUNTFILE | grep '^USER:' | sed 's/^USER:\s*//')"
		MYSQL_PWD="$(cat $VHOST_ACCOUNTFILE | grep '^PWD_MYSQL:' | sed 's/^PWD_MYSQL:\s*//')"
		USER_GRIVE_EMAIL="$(cat $VHOST_ACCOUNTFILE | grep '^GRIVE_EMAIL:' | sed 's/^GRIVE_EMAIL:\s*//')"
		[ "x$USER_GRIVE_EMAIL" = "x" ] && USER_GRIVE_EMAIL="$GRIVE_EMAIL"
		if [ "x$USER_GRIVE_EMAIL" = "x$GRIVE_EMAIL" -o "x$USER_GRIVE_EMAIL" = "x" ]; then
			USER_GRIVE_DIR="$GRIVE_DIR"
			USER_GRIVE_SUBDIR_BACKUPS="$GRIVE_SUBDIR_BACKUPS"
			USER_GRIVE_EMAIL="";
		else
			USER_GRIVE_EMAIL="$(echo $USER_GRIVE_EMAIL | sed -E 's;[^@]*;;g' )"
			USER_GRIVE_DIR="$(cat $VHOST_ACCOUNTFILE | grep '^GRIVE_DIR:' | sed 's/^GRIVE_DIR:\s*//')"
			if [ "x$USER_GRIVE_DIR" = "x" ]; then
				USER_GRIVE_SUBDIR_BACKUPS="$(cat $VHOST_ACCOUNTFILE | grep '^GRIVE_SUBDIR_BACKUPS:' | sed 's/^GRIVE_SUBDIR_BACKUPS:\s*//' | sed -E 's;^(/*)(.*[^/])*(/*)$;\2;g' )"
				if [ "$USER_GRIVE_EMAIL" = "@" ]; then
					USER_GRIVE_DIR="$VHOST_PATH/gDrive"
				else
					USER_GRIVE_DIR="$VHOST_PATH"
				fi
				[ "x$USER_GRIVE_SUBDIR_BACKUPS" = "x" ] && USER_GRIVE_SUBDIR_BACKUPS="$GRIVE_SUBDIR_BACKUPS"
			fi
		fi
		[ ! -e "$USER_GRIVE_DIR" -o ! -e "$USER_GRIVE_DIR/$GRIVE_SUBDIR_BACKUPS" ] && \
			( 	mkdir -p "$USER_GRIVE_DIR/$GRIVE_SUBDIR_BACKUPS" && \
				[ "x$USER_GRIVE_DIR" != "x$VHOST_PATH" ] && \
				(	chown "$USER":"$WWW_GROUP" "$USER_GRIVE_DIR" && \
					chmod 700 "$USER_GRIVE_DIR"  && \
					touch "$USER_GRIVE_DIR/.backup-ignore" ) && \
				chown "$USER":"$WWW_GROUP" "$USER_GRIVE_DIR/$USER_GRIVE_SUBDIR_BACKUPS" && \
				chmod 700 "$USER_GRIVE_DIR/$USER_GRIVE_SUBDIR_BACKUPS" \
				touch "$USER_GRIVE_DIR/$GRIVE_SUBDIR_BACKUPS/.backup-ignore" && \
				chown "$USER":"$WWW_GROUP" "$USER_GRIVE_DIR/$USER_GRIVE_SUBDIR_BACKUPS/.backup-ignore" )
		if [ "x$RSYNC_ONLY" = "x" ]; then
			FIND_OPT_DIFF_BACKUP=""
			TAR_OPT_DIFF_BACKUP=""
			if [ "x$DIFF_BACKUP" = 'xDIFF' -o "x$DIFF_BACKUP" = 'xDATE' ]; then
				if [ "x$DIFF_BACKUP" = 'xFILE' ]; then
					if [ "x$DB_ONLY" = "xDB-ONLY" ]; then
						DIFF_BACKUPFILE="$(ls -t -1 $USER_GRIVE_DIR/$GRIVE_SUBDIR_BACKUPS/$VHOST_HOSTNAME-db-*.sql | head -n 1)"
					else
						DIFF_BACKUPFILE="$(ls -t -1 $USER_GRIVE_DIR/$GRIVE_SUBDIR_BACKUPS/$VHOST_HOSTNAME*.tbz | head -n 1)"
					fi
				else
					if [ "x$DIFF_BACKUP" = 'xDATE' ]; then
						DIFF_BACKUPFILE="$FILE_TIMEMARK"
					fi
				fi
			fi
			cd "$VHOST_PATH"
			mysqldump --opt "$USER" > "dump-$USER.sql" -u "$USER" --password="$MYSQL_PWD" || exit_with_error "BACKUP DATABASE $VHOST NON ESEGUITO CORRETTAMENTE"
			if [ "x$DB_ONLY" = "xDB-ONLY" ]; then
				if [ -e "$DIFF_BACKUPFILE" -a "x$DIFF_BACKUP" = "xFILE" ]; then
					DIFF_DUMP_TIMEMARK="$(date -d "$(stat -c %y $DIFF_BACKUPFILE)"  "+%Y%m%d%H%M")"
					diff "$DIFF_BACKUPFILE" "$VHOST_PATH/dump-$USER.sql" > "$VHOST_PATH/dump-$USER-$DIFF_DUMP_TIMEMARK-$TIMEMARK.diff"
				else
					if [ "x$DIFF_BACKUP" = 'xFILE' ]; then
						FIND_OPT_DIFF_BACKUP=""
						TAR_OPT_DIFF_BACKUP=""
						DIFF_DUMP_TIMEMARK=""
					fi
				fi
			else
				if [ -e "$DIFF_BACKUPFILE" -a "x$DIFF_BACKUP" = "xFILE" ]; then
					FIND_OPT_DIFF_BACKUP=" -newer $FILE_TIMEMARK"
					TAR_OPT_DIFF_BACKUP=" --newer=$DIFF_BACKUPFILE"
					cd "$TMP_BACKUP"
					tar -xjf $DIFF_BACKUPFILE "./dump-$USER.sql" 
					DIFF_DUMP_TIMEMARK="$(date -d "$(stat -c %y $DIFF_BACKUPFILE)"  "+%Y%m%d%H%M")"
					mv "dump-$USER.sql" "dump-$USER-$DIFF_DUMP_TIMEMARK.sql"
					diff "dump-$USER-$DIFF_DUMP_TIMEMARK.sql" "$VHOST_PATH/dump-$USER.sql" > "$VHOST_PATH/dump-$USER-$DIFF_DUMP_TIMEMARK-$TIMEMARK.diff"
					cd "$VHOST_PATH"
					chown "$USER":"$WWW_GROUP" "dump-$USER-$DIFF_DUMP_TIMEMARK-$TIMEMARK.diff"
					chmod 600 "dump-$USER-$DIFF_DUMP_TIMEMARK-$TIMEMARK.diff"
				else
					if [ "x$DIFF_BACKUP" = 'xDATE' ]; then
						FIND_OPT_DIFF_BACKUP=" -newer $FILE_TIMEMARK"
						TAR_OPT_DIFF_BACKUP=" --newer=$FILE_TIMEMARK"
						DIFF_DUMP_TIMEMARK="$START_TIMEMARK"
					else
						FIND_OPT_DIFF_BACKUP=""
						TAR_OPT_DIFF_BACKUP=""
						DIFF_DUMP_TIMEMARK=""
					fi
				fi
			fi
			[ -e "$TMP_BACKUP" ] && \
				( rm -R "$TMP_BACKUP" || exit_with_error "ERROR: CANNOT REMOVE TMP DIRECTORY" )

			if [ "x$TAR_OPT_DIFF_BACKUP" = "x" ]; then
				BACKUPNAME="$VHOST_HOSTNAME-$TIMEMARK"
			else
				BACKUPNAME="$VHOST_HOSTNAME-$DIFF_DUMP_TIMEMARK-$TIMEMARK"
			fi
			if [ "x$DB_ONLY" = "xDB-ONLY" ]; then
				BACKUPNAME="$( echo $BACKUPNAME | sed -E "s;$VHOST_HOSTNAME-;$VHOST_HOSTNAME-db-$USER-;g" )"
				mv "dump-$USER.sql" "$USER_GRIVE_DIR/$GRIVE_SUBDIR_BACKUPS/$BACKUPNAME.sql" || exit_with_error "BACKUP DATABASE '$VHOST_HOSTNAME' NON ESEGUITO CORRETTAMENTE"
				chown "$USER":"$WWW_GROUP" "$USER_GRIVE_DIR/$GRIVE_SUBDIR_BACKUPS/$BACKUPNAME.sql" || exit_with_error "BACKUP DATABASE '$VHOST_HOSTNAME' NON ESEGUITO CORRETTAMENTE"
				if [  "x$DIFF_BACKUP" = 'xFILE' -a "x$DIFF_BACKUPFILE" != "x" ]; then
					BACKUPNAME_DIFF="$VHOST_HOSTNAME-db-$USER-$DIFF_DUMP_TIMEMARK-$TIMEMARK"
					mv "dump-$USER-$DIFF_DUMP_TIMEMARK-$TIMEMARK.diff" "$USER_GRIVE_DIR/$GRIVE_SUBDIR_BACKUPS/$BACKUPNAME_DIFF.sql.diff" || exit_with_error "BACKUP DIFF DATABASE '$VHOST_HOSTNAME' NON ESEGUITO CORRETTAMENTE"
					chown "$USER":"$WWW_GROUP" "$USER_GRIVE_DIR/$GRIVE_SUBDIR_BACKUPS/$BACKUPNAME_DIFF.sql.diff" || exit_with_error "BACKUP DIFF DATABASE '$VHOST_HOSTNAME' NON ESEGUITO CORRETTAMENTE"
				fi
			else
				chown "$USER":"$WWW_GROUP" "dump-$USER.sql" || exit_with_error "BACKUP DATABASE '$VHOST_HOSTNAME' NON ESEGUITO CORRETTAMENTE"
				chmod 600 "dump-$USER.sql" || exit_with_error "BACKUP DATABASE '$VHOST_HOSTNAME' NON ESEGUITO CORRETTAMENTE"
				if [ "x$APACHE_CONF" = "xSAVE" ]; then
					cp -f "/etc/apache2/sites-available/$VHOST_HOSTNAME" "apache2-vhost.conf" || exit_with_error "BACKUP CONF APACHE '$VHOST_HOSTNAME' NON ESEGUITO CORRETTAMENTE"
					chown "$USER":"$WWW_GROUP" "apache2-vhost.conf" || exit_with_error "BACKUP CONF APACHE '$VHOST_HOSTNAME' NON ESEGUITO CORRETTAMENTE"
					chmod 600 "apache2-vhost.conf"  || exit_with_error "BACKUP CONF APACHE '$VHOST_HOSTNAME' NON ESEGUITO CORRETTAMENTE"
				fi
				if [ "x$SAMBA_CONF" = "xSAVE" ]; then
					cp -f "/etc/samba/smb.conf.d/$VHOST_HOSTNAME.smb.conf" "samba-share.conf" || exit_with_error "BACKUP CONF SAMBA '$VHOST_HOSTNAME' NON ESEGUITO CORRETTAMENTE"
					chown "$USER":"$WWW_GROUP" "samba-share.conf" || exit_with_error "BACKUP CONF SAMBA '$VHOST_HOSTNAME' NON ESEGUITO CORRETTAMENTE"
					chmod 600 "dump-$USER.sql" "samba-share.conf" || exit_with_error "BACKUP CONF SAMBA '$VHOST_HOSTNAME' NON ESEGUITO CORRETTAMENTE"
				fi
				find . \! \( -name "*.tbz" -o -name "*.tbz.log"  -o -name "*.jpa" \) -fprintf "filelist-$TIMEMARK.ls" "%u:%g\t%m\t%s\t%p\n"
				find . $FIND_OPT_DIFF_BACKUP -type f -a \! \( -name "*.tbz" -o -name "*.tbz.log"  -o -name "*.jpa" \) > "list-files2tar-$TIMEMARK.ls"
				for BACKUP_IGNORE_DIR in $(cat "list-files2tar-$TIMEMARK.ls" | grep .backup-ignore | sed -E 's;^(.*)/.backup-ignore;\1;'); do
					cat "list-files2tar-$TIMEMARK.ls" | grep -v $BACKUP_IGNORE_DIR >  "tmplist-files2tar-$TIMEMARK.ls"
					rm "list-files2tar-$TIMEMARK.ls"
					mv "tmplist-files2tar-$TIMEMARK.ls" "list-files2tar-$TIMEMARK.ls"
				done
				chown "$USER":"$WWW_GROUP" "filelist-$TIMEMARK.ls" "list-files2tar-$TIMEMARK.ls" || exit_with_error "BACKUP FILELIST '$VHOST_HOSTNAME' NON ESEGUITO CORRETTAMENTE"
				chmod 600 "filelist-$TIMEMARK.ls" "list-files2tar-$TIMEMARK.ls" || exit_with_error "BACKUP FILELIST '$VHOST_HOSTNAME' NON ESEGUITO CORRETTAMENTE"
				tar -cvjf "$USER_GRIVE_DIR/$GRIVE_SUBDIR_BACKUPS/$BACKUPNAME.tbz" --files-from="list-files2tar-$TIMEMARK.ls" > "$USER_GRIVE_DIR/$GRIVE_SUBDIR_BACKUPS/$BACKUPNAME.tbz.log" 2>&1 
				TAR_EXIT_STATUS=$?
				if [ $TAR_EXIT_STATUS -eq 1 ]; then
					exit_with_error "BACKUP TAR (Some files differ) '$VHOST_HOSTNAME' NON ESEGUITO CORRETTAMENTE: ELIMINARE MANUALMENTE IL FILE: '$USER_GRIVE_DIR/$GRIVE_SUBDIR_BACKUPS/$BACKUPNAME.tbz'"
				elif [ $TAR_EXIT_STATUS -eq 2 ]; then
					exit_with_error "BACKUP TAR (fatal error) '$VHOST_HOSTNAME' NON ESEGUITO CORRETTAMENTE: ELIMINARE MANUALMENTE IL FILE: '$USER_GRIVE_DIR/$GRIVE_SUBDIR_BACKUPS/$BACKUPNAME.tbz'"
				fi
				chown "$USER":"$WWW_GROUP" "$USER_GRIVE_DIR/$GRIVE_SUBDIR_BACKUPS/$BACKUPNAME.tbz" || exit_with_error "BACKUP TAR '$VHOST_HOSTNAME' NON ESEGUITO CORRETTAMENTE"
				chmod 600 "$USER_GRIVE_DIR/$GRIVE_SUBDIR_BACKUPS/$BACKUPNAME.tbz" || exit_with_error "BACKUP TAR '$VHOST_HOSTNAME' NON ESEGUITO CORRETTAMENTE"
				rm "dump-$USER.sql" "filelist-$TIMEMARK.ls" "list-files2tar-$TIMEMARK.ls" || exit_with_error "CLEAN TMP FILES '$VHOST_HOSTNAME' NON ESEGUITO CORRETTAMENTE"
				[ -e "dump-$USER-$DIFF_DUMP_TIMEMARK-$TIMEMARK.diff" ] && ( rm "dump-$USER-$DIFF_DUMP_TIMEMARK-$TIMEMARK.diff" || exit_with_error "CLEAN TMP FILES '$VHOST_HOSTNAME' NON ESEGUITO CORRETTAMENTE" )
				[ "x$APACHE_CONF" = "xSAVE" ] && ( rm "apache2-vhost.conf" || exit_with_error "CLEAN TMP FILES '$VHOST_HOSTNAME' NON ESEGUITO CORRETTAMENTE" )
				[ "x$SAMBA_CONF" = "xSAVE" ] && ( rm "samba-share.conf"  || exit_with_error "CLEAN TMP FILES '$VHOST_HOSTNAME' NON ESEGUITO CORRETTAMENTE" )
			fi
			
			if [ "x$DIFF_BACKUP" = "x" ]; then
				echo "  BACKUP $VHOST_HOSTNAME ESEGUITO CORRETTAMENTE"
				if [ "x$DB_ONLY" = "xDB-ONLY" ]; then
					echo "  	CREATO: '$USER_GRIVE_DIR/$GRIVE_SUBDIR_BACKUPS/$BACKUPNAME.sql'"
				else
					echo "  	CREATO: '$USER_GRIVE_DIR/$GRIVE_SUBDIR_BACKUPS/$BACKUPNAME.tbz'"
				fi
			else
				if [ "x$DIFF_BACKUP" = "xFILE" ]; then
					echo "  BACKUP DIFFERENZIALE DI '$VHOST_HOSTNAME' ESEGUITO CORRETTAMENTE"
					if [ "x$DB_ONLY" = "xDB-ONLY" ]; then
						echo "  	CREATO: '$USER_GRIVE_DIR/$GRIVE_SUBDIR_BACKUPS/$BACKUPNAME.sql'"
						echo "  	COTENENTE COPIA DEL DATABASE"
						echo "  	CREATO: '$USER_GRIVE_DIR/$GRIVE_SUBDIR_BACKUPS/$BACKUPNAME_DIFF.sql.diff'"
					else
						echo "  	CREATO: '$USER_GRIVE_DIR/$GRIVE_SUBDIR_BACKUPS/$BACKUPNAME.tbz'"
					fi
					echo "  	COTENENTE LE VARIAZIONI DAL PRECEDENTE: '$DIFF_BACKUPFILE'"
				else 
					if [ "x$DIFF_BACKUP" = "xDATE" ]; then
						echo "  BACKUP DEGLI ULTIMI $DIFF_NDAYS GIORNI DI '$VHOST_HOSTNAME' ESEGUITO CORRETTAMENTE"
						if [ "x$DB_ONLY" = "xDB-ONLY" ]; then
							echo "  	CREATO: '$USER_GRIVE_DIR/$GRIVE_SUBDIR_BACKUPS/$BACKUPNAME.sql'"
						else
							echo "  	CREATO: '$USER_GRIVE_DIR/$GRIVE_SUBDIR_BACKUPS/$BACKUPNAME.tbz'"
						fi
					fi
				fi
			fi
		fi
		# RSYNC
		USER_RSYNC="$(cat $VHOST_ACCOUNTFILE | grep '^RSYNC:' | sed 's/^RSYNC:\s*//')"
		if [ "x$USER_RSYNC" != "x" ]; then
				USER_GRIVE_SUBDIR_RSYNC="$(cat $VHOST_ACCOUNTFILE | grep '^GRIVE_SUBDIR_RSYNC:' | sed 's/^GRIVE_SUBDIR_RSYNC:\s*//')"
				[ "x$USER_GRIVE_SUBDIR_RSYNC" = "x" ] && USER_GRIVE_SUBDIR_RSYNC="$GRIVE_SUBDIR_RSYNC"
				[ ! -e "$USER_GRIVE_DIR/$USER_GRIVE_SUBDIR_RSYNC" ] && mkdir -p "$USER_GRIVE_DIR/$USER_GRIVE_SUBDIR_RSYNC"
				for rsync_item in $USER_RSYNC; do
						[ "x$rsync_item" = "x" ] && continue
						rsync_from="$( echo "$rsync_item" | sed -E 's/^([^:]*):?(.*)$/\1/' )"
						if [ "x$rsync_from" = "x$rsync_item" ]; then
								rsync_to="$rsync_from"
						else
								rsync_to="$( echo "$rsync_item" | sed -E 's/^([^:]*):?(.*)$/\2/' )"
						fi
						[ ! -d "$VHOST_PATH/$HTTPDOCS_DIR/$rsync_from" ] && continue
						[ ! -d "$USER_GRIVE_DIR/$USER_GRIVE_SUBDIR_RSYNC/$rsync_to" ] && mkdir -p "$USER_GRIVE_DIR/$USER_GRIVE_SUBDIR_RSYNC/$rsync_to"
						rsync -rlptgovv --delete "$VHOST_PATH/$HTTPDOCS_DIR/$rsync_from/" "$USER_GRIVE_DIR/$USER_GRIVE_SUBDIR_RSYNC/$rsync_to/"
				done
		fi
		if [ "x$USER_GRIVE_EMAIL" = 'x@' -a -e "$USER_GRIVE_DIR" ]; then
			cd "$USER_GRIVE_DIR"
			grive
		fi
	done
	if [ "x$VHOST" = "x*" -a "$(echo $GRIVE_EMAIL | sed -E 's;[^@]*;;g' )" = '@' -a -e "$GRIVE_DIR" ]; then
		cd "$GRIVE_DIR"
		grive
	fi
else
	exit_with_error "ERROR: CANNOT OPEN $VHOSTS_DIR"
fi
[ "x$DIFF_NDAYS" != 'x' -a -e "$FILE_TIMEMARK" ] && \
	rm "$FILE_TIMEMARK"
cd "$PWD_SRC"
exit 0
