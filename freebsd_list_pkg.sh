#!/bin/sh
#
# SFS.it Maintenance Server Tools 
# BSD style KISS scripts
#
# LIST OF PKG installed on a FreeBSD BOX
#
# Written by Agostino Zanutto (agostino@sfs.it) for SFS.it MST
#

if [ "x$1" = "x" ]; then
	pkg info | awk '{print $1;}' | sed 's/-[^-]*$//' | perl -p -e 's/\n/ /'
elif [ "x$2" = "x" ]; then
	echo "filter results: $1"
	pkg info | awk '{print $1;}' | sed 's/-[^-]*$//' | perl -p -e 's/\n/ /' | grep "$1"
else
	echo  "replace \"$2\" with \"$3\""
	pkg info | awk '{ print $1; }' | sed 's/-[^-]*$//' | perl -p -e 's/\n/ /' | grep $1 | sed -e "s/$2/$3/g"
fi
#EOF
