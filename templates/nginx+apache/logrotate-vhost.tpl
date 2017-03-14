# APACHE LOGS FOR  {$VHOST} 
 
{$VHOSTS_DIR}/{$VHOST}/logs/*.log {
        daily
        missingok
        rotate 5844
		# 12 Years
        compress
        delaycompress
        notifempty
        create 640 {$USER} {$WWW_GROUP}
        sharedscripts
        postrotate
		[ ! -f /var/run/nginx.pid ] || kill -USR1 `cat /var/run/nginx.pid` > /dev/null
                [ ! -f /var/run/httpd.pid ] || kill -HUP `cat /var/run/httpd.pid` > /dev/null
        endscript
}

# END OF LOGROTATE {$VHOST}
