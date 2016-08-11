#!/bin/sh

old_uid=$1
old_uid_gid_www=$2
user=$3
user_grp_www=$4
chown $user:$user_grp_www logs/* > /dev/null
find . -uid $old_uid -exec chown $user {} \;
find . -uid $old_uid_gid_www -exec chown $user_grp_www {} \;
find . -gid $old_uid_gid_www -exec chgrp $user_grp_www {} \;
