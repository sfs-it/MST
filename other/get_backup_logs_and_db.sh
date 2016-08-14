#!/bin/sh
PWD=$(pwd)
for host in $(find . -maxdepth 1 -name "www*" ); do
	host=$(echo $host | sed 's/^\.\///')
	echo $host
	rm $host/*.sql
	sh /root/bin/SFSit_MST/backup.sh db-only $host $PWD/$host
	tar -cjf $host.tar.bz2 $host/logs $host/*.sql
done
tar -cvf all_vhosts_logs.tar *.bz2
rm *.bz2
