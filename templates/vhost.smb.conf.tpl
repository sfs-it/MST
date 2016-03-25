; SHARE FOR {$VHOST} /{$USER}

[vhost {$VHOST}]
   path = {$VHOSTS_DIR}/{$VHOST}/
   comment = apache {$VHOST} httpdocs root
   browseable = yes
   writable = yes
   create mask = 0640
   directory mask = 0750
   valid users = @{$WWW_GROUP}
   write list = @{$WWW_GROUP}
   force user = {$USER}
   force group = {$WWW_GROUP}
   vfs objects = recycle
   recycle:repository = .recycle
   recycle:keeptree = yes
   recycle:versions = yes


; END OF SHARE FOR {$VHOST}
