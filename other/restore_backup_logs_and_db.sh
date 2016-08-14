#!/bin/sh

SETTINGS_FILE="/etc/SFSit_MST.conf.sh"
test -s "/root/SFSit_MST.conf.sh" && SETTINGS_FILE="/root/SFSit_MST.conf.sh"
if [ -s "$SETTINGS_FILE" ]; then
        VHOSTS_DIR="$(sh "$SETTINGS_FILE" VHOSTS_DIR)"
        WWW_GROUP="$(sh "$SETTINGS_FILE" WWW_GROUP)"
fi
PWD=$(pwd)
for host in $(find . -maxdepth 1 -name "www*" ); do
	host=$(echo $host | sed 's/^\.\///')
	echo $host
	USER=$(sh /root/bin/MST/subs/get-account-user.sh $host)
	if [ "x$( echo $USER | sed -E 's/^(ERROR)(:.*)$/\1/')" = "xERROR" ]; then
		echo "* no valid user for $host, skip"
		continue
	fi
	#sh /root/bin/SFSit_MST/subs/restorebackup.sh db-only $host $PWD/$host/$host*.sql
	chown -R $USER:$WWW_GRP $PWD/$host/logs
	mv $PWD/$host/logs/* $VHOSTS_DIR/$host/logs
done
