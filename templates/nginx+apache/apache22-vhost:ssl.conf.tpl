# ######################### #
# VIRTUALHOST SSL FOR {$VHOST_HOSTNAME}
# ######################### #

#<VirtualHost {$SERVER_IP}:{$APACHE_HTTPS}>
<VirtualHost *:{$APACHE_HTTPS}>
	ServerName  {$VHOST}.local
	ServerAlias {$VHOST_HOSTNAME}
{$SERVER_ALIASES}

	ServerAdmin  {$ADMIN_EMAIL}

	DocumentRoot {$VHOSTS_DIR}/{$VHOST}/{$HTTPDOCS_DIR}
	<Directory />
		Options FollowSymLinks
		AllowOverride None
	</Directory>
	<Directory {$VHOSTS_DIR}/{$VHOST}/{$HTTPDOCS_DIR}>
		Options Indexes FollowSymLinks MultiViews
		AllowOverride All
		Order allow,deny
		allow from all
	</Directory>

	ScriptAlias /cgi-bin/ /usr/lib/cgi-bin/
	<Directory "/usr/lib/cgi-bin">
		AllowOverride None
		Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch
		Order allow,deny
		Allow from all
	</Directory>

	ErrorLog {$VHOSTS_DIR}/{$VHOST}/{$HTTPLOGS_DIR}/error-apache.log
	# Possible values include: debug, info, notice, warn, error, crit, alert, emerg.
	LogLevel warn
	CustomLog {$VHOSTS_DIR}/{$VHOST}/{$HTTPLOGS_DIR}/access-apache.log combined
	SSLEngine on
	SSLCertificateFile    /usr/local/etc/letsencrypt/live/{$VHOST_HOSTNAME}/cert.pem
	SSLCertificateKeyFile /usr/local/etc/letsencrypt/live/{$VHOST_HOSTNAME}/privkey.pem
	SSLCertificateChainFile /usr/local/etc/letsencrypt/live/{$VHOST_HOSTNAME}/fullchain.pem
	
	<FilesMatch "\.(cgi|shtml|phtml|php)$">
	   SSLOptions +StdEnvVars
	</FilesMatch>
	
	BrowserMatch "MSIE [2-6]" \
	nokeepalive ssl-unclean-shutdown \
	downgrade-1.0 force-response-1.0
	BrowserMatch "MSIE [17-9]" ssl-unclean-shutdown
</VirtualHost>
