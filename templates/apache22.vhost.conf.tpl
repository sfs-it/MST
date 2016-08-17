# ######################### #
# VIRTUALHOST FOR {$VHOST}
# ######################### #

<VirtualHost *:80>
	ServerName {$VHOST_HOSTNAME}
{$SERVER_ALIASES}
	ServerAdmin {$ADMIN_EMAIL}

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

	ErrorLog {$VHOSTS_DIR}/{$VHOST}/{$HTTPLOGS_DIR}/error.log
	# Possible values include: debug, info, notice, warn, error, crit, alert, emerg.
	LogLevel warn
	CustomLog {$VHOSTS_DIR}/{$VHOST}/{$HTTPLOGS_DIR}/access.log combined
</VirtualHost>

# ################################################################################## #
# Alias for http://{$HOSTNAME}/{$USER}
#           http://{$HOSTNAME}/{$VHOST} 
# ################################################################################## #

Alias /{$USER} {$VHOSTS_DIR}/{$VHOST}/{$HTTPDOCS_DIR}
Alias /{$VHOST} {$VHOSTS_DIR}/{$VHOST}/{$HTTPDOCS_DIR}

<Directory {$VHOSTS_DIR}/{$VHOST}/{$HTTPDOCS_DIR}>
	Options Indexes FollowSymLinks MultiViews
	AllowOverride All
	Order allow,deny
	allow from all
</Directory>

