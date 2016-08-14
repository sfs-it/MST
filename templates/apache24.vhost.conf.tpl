# ######################### #
# VIRTUALHOST FOR {$DOMAIN}
# ######################### #

<VirtualHost *:80>
	ServerName   {$VHOST}
{$SERVER_ALIASES}
	ServerAdmin  {$ADMIN_EMAIL}

	DocumentRoot {$VHOSTS_DIR}/{$VHOST}/{$HTTPDOCS_DIR}
	<Directory />
		Options FollowSymLinks
		AllowOverride None
	</Directory>
	<Directory {$VHOSTS_DIR}/{$VHOST}/{$HTTPDOCS_DIR}>
                AllowOverride FileInfo AuthConfig Limit Indexes
                Options MultiViews Indexes SymLinksIfOwnerMatch IncludesNoExec FollowSymLinks
                AllowOverrideList Redirect RedirectMatch
                Require method GET POST OPTIONS
        </Directory>


        ScriptAlias /cgi-bin/ /usr/lib/cgi-bin/
        <Directory "/usr/lib/cgi-bin">
                AllowOverride None
                Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch
                Require all granted
        </Directory>

	ErrorLog {$VHOSTS_DIR}/{$VHOST}/{$HTTPLOGS_DIR}/error.log
	# Possible values include: debug, info, notice, warn, error, crit, alert, emerg.
	LogLevel warn
	CustomLog {$VHOSTS_DIR}/{$VHOST}/{$HTTPLOGS_DIR}/access.log combined
</VirtualHost>

# ################################################################################## #
# Alias for http:/{$HOSTNAME}/{$USER}
#           http:/{$HOSTNAME}/{$VHOST_ONDOMAIN} 
#           http:/{$HOSTNAME}/{$VHOST}
#           http:/{$HOSTNAME}/{$DOMAIN}
# ################################################################################## #

Alias /{$USER} {$VHOSTS_DIR}/{$VHOST}/{$HTTPDOCS_DIR}
Alias /{$VHOST_ONDOMAIN} {$VHOSTS_DIR}/{$VHOST}/{$HTTPDOCS_DIR}
Alias /{$VHOST} {$VHOSTS_DIR}/{$VHOST}/{$HTTPDOCS_DIR}
# Alias /{$DOMAIN} {$VHOSTS_DIR}/{$VHOST}/{$HTTPDOCS_DIR}
<Directory {$VHOSTS_DIR}/{$VHOST}/{$HTTPDOCS_DIR}>
	AllowOverride FileInfo AuthConfig Limit Indexes
	Options MultiViews Indexes SymLinksIfOwnerMatch IncludesNoExec FollowSymLinks
	AllowOverrideList Redirect RedirectMatch
	Require method GET POST OPTIONS
</Directory>


