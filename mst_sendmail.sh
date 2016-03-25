#!/bin/sh
#
# SFS.it Maintenance Server Tools 
# BSD style KISS scripts
#
# FILE MODIFIED CHECKER SINCE N DAYS
#
# Written by Agostino Zanutto (agostino@sfs.it) for SFS.it MST
#
#
# build multipart email and send it with ssmtp
#
exit_with_error(){
	test 'x' != "x$1" && echo "$1"
	exit 1
}
if [ "$( uname )" = 'FreeBSD' ]; then
	MTA='/usr/local/sbin/ssmtp'
	MD5='md5'
elif [ "$( uname )" = 'Linux' ]; then
	MTA='/usr/sbin/ssmtp'
	MD5='md5sum'
fi

mst_sendmail(){
	# $1 sender
	# $2 target
	# $3 subject
	# $4 first file to attach (no multipart if only one file)
	# $5....$X files to attach
	test 'x' != "x$1" || exit_with_error "mst_sendmail *SENDER* TARGET SUBJECT BODY|FILE_CONTENT [ATTACH_FILE_LIST]"
	test 'x' != "x$2" || exit_with_error "mst_sendmail SENDER *TARGET* SUBJECT BODY|FILE_CONTENT [ATTACH_FILE_LIST]"
	test 'x' != "x$3" || exit_with_error "mst_sendmail SENDER TARGET *SUBJECT* BODY|FILE_CONTENT [ATTACH_FILE_LIST]"
	test 'x' != "x$4" || exit_with_error "mst_sendmail SENDER TARGET SUBJECT *BODY|FILE_CONTENT* [ATTACH_FILE_LIST]"
	test -x $MTA || exit_with_error "sendmail require to install ssmtp"
	SENDER="$1"
	TARGET="$2"
	SUBJECT="$3"
	FILE_CONTENT="$4"
	ATTACH_FILE_LIST="$5"
	TIMEMARK="$(echo "$(date "+%Y%m%d%H%M%S%N")" | $MD5 | sed -e 's/\s*-$//' )"
	test -e "$SUBJECT" && SUBJECT="$( cat "$SUBJECT" )"
	FILE_TIMEMARK="/tmp/MAILBODY-$TIMEMARK.tmp"
	touch "$FILE_TIMEMARK"
	if [ 'x' != "x$ATTACH_FILE_LIST" -a -s "$ATTACH_FILE_LIST"  ]; then
		# multipart email
		MIME_COSTRUCT="$(which mime-construct)"
		if [ $? -eq 1 ]; then
			exit_with_error "mime-construct program needed."
		fi
		if [ -e "$FILE_CONTENT" ]; then
			BODY="$(cat "$FILE_CONTENT")"
		else
			BODY=$FILE_CONTENT
		fi
		CMD="$MIME_COSTRUCT --to \"$TARGET\" --subject \"$SUBJECT\" --body \"$BODY\""
		for ATTACH_FILE in $(cat "$ATTACH_FILE_LIST"); do
			if [ 'x' != "x$ATTACH_FILE" -a -s "$ATTACH_FILE"  ]; then
				CMD="$CMD --type $(file --mime-type -b "$ATTACH_FILE") --file-attach \"$ATTACH_FILE\""
			fi
		done
		CMD="$CMD --output"
		eval "$CMD > $FILE_TIMEMARK-mimecontent"
		if [ $? -eq 0 ]; then
			( echo "FROM: $SENDER" && cat "$FILE_TIMEMARK-mimecontent" ) > "$FILE_TIMEMARK"
			rm "$FILE_TIMEMARK-mimecontent"
			cat "$FILE_TIMEMARK" | $MTA $TARGET
		fi
		mta_RETURN=$?
	else
		# single file send
		echo "FROM: $SENDER" > "$FILE_TIMEMARK"
		echo "TO: $TARGET" >> "$FILE_TIMEMARK"
		echo "SUBJECT: $SUBJECT" >> "$FILE_TIMEMARK"
		echo "" >> "$FILE_TIMEMARK"
		echo "" >> "$FILE_TIMEMARK"
		if [ -e "$FILE_CONTENT" ]; then
			cat $FILE_CONTENT >> "$FILE_TIMEMARK"
		else
			echo $FILE_CONTENT >> "$FILE_TIMEMARK"
		fi
		cat "$FILE_TIMEMARK" | $MTA $TARGET
		mta_RETURN=$?
	fi
	test $mta_RETURN -eq 0 || exit_with_error "ERROR SENDING '$FILE_TIMEMARK'"
	rm "$FILE_TIMEMARK" || exit_with_error "CANNOT remove file '$FILE_TIMEMARK'"
	return $mta_RETURN
}
MTA_SCRIPT="$(basename $0)"
if [ "x$MTA_SCRIPT" = "xmst_sendmail.sh" ]; then
	mst_sendmail "$1" "$2" "$3" "$4"
	exit $?
fi
