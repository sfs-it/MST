; SHARE FOR {$VHOST} /{$USER}

[vhost {$VHOST}]
   path = {$VHOSTS_DIR}/{$VHOST}/
   comment = apache {$VHOST} httpdocs root
   browseable = yes
   writable = yes
   create mask = 0640
   directory mask = 0750
   valid users = @www-data
   write list = @www-data
   force user = {$USER}
   force group = www-data
   vfs objects = recycle
   recycle:repository = .recycle
   recycle:keeptree = yes
   recycle:versions = yes


; END OF SHARE FOR {$VHOST}
