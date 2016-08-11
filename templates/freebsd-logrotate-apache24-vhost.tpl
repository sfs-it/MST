# APACHE LOGS FOR  {$VHOST} 
 
{$VHOSTS_DIR}/{$VHOST}/logs/*.log {
        daily
        missingok
        rotate 5844
		# 12 Years
        compress
        delaycompress
        notifempty
        create 640 {$USER} adm
        sharedscripts
        postrotate
                /etc/init.d/apache2 reload > /dev/null
        endscript
}

# END OF LOGROTATE {$VHOST}
