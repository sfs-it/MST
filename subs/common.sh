#!/bin/sh
#
# SFS.it Maintenance Server Tools 
# BSD style KISS scripts
#
# Written by Agostino Zanutto (agostino@sfs.it) for SFS.it MST
#
# COMMON PROCEDUERES CALL
#

exit_with_error(){
	test 'x' != "x$1" && echo "$1"
	test 'x' != "x$2" && exit 1
	exit $2
}
