#!/bin/sh
#
# SFS.it Maintenance Server Tools 
# BSD style KISS scripts
#
# LIST OF PKG installed on a FreeBSD BOX
#
# Written by Agostino Zanutto (agostino@sfs.it) for SFS.it MST
#

if [ "x$2" != "x" ]; then
	pkg info | awk '{print $1;}' | sed 's/-[^-]*$//' | perl -p -e 's/\n/ /' | grep $1 |sed -e "s/$2/$3/g"
elif [ "x$1" != "x" ]; then
	pkg info | awk '{print $1;}' | sed 's/-[^-]*$//' | perl -p -e 's/\n/ /' | grep "$1"
else
	pkg info | awk '{print $1;}' | sed 's/-[^-]*$//' | perl -p -e 's/\n/ /'
fi
