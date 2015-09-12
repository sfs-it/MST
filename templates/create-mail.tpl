CREATED A NEW USER FOR http://{$HOSTNAME}

DOMAIN {$DOMAIN}

VHOST: http://{$VHOST}
VHOST-ALIAS: http://{$VHOST_ONDOMAIN}.{$MY_DOMAIN}
             http://{$HOSTNAME}/{$USER}
             http://{$HOSTNAME}/{$VHOST_ONDOMAIN}
             http://{$HOSTNAME}/{$VHOST}

USER: {$USER}
UID: {$UID}
GID: {$GID}
PWD_FTP: {$PWD_FTP}
PWD_MYSQL: {$PWD_MYSQL}

WEBMASTER EMAIL: webmaster@{$DOMAIN}
