# ######################### #
# VIRTUALHOST FOR {$DOMAIN}
# ######################### #

<VirtualHost *:80>
	ServerName   {$VHOST}
	ServerAlias  {$DOMAIN}
	ServerAlias  {$VHOST_ONDOMAIN}.{$MY_DOMAIN}

	ServerAdmin  {$ADMIN_EMAIL}

	DocumentRoot {$VHOSTS_DIR}/{$VHOST}/httpdocs
	<Directory />
		Options FollowSymLinks
		AllowOverride None
	</Directory>
	<Directory {$VHOSTS_DIR}/{$VHOST}/httpdocs>
                AllowOverride FileInfo AuthConfig Limit Indexes
                Options MultiViews Indexes SymLinksIfOwnerMatch IncludesNoExec FollowSymLinks
                Require method GET POST OPTIONS
                Require all granted
        </Directory>

        ScriptAlias /cgi-bin/ /usr/lib/cgi-bin/
        <Directory "/usr/lib/cgi-bin">
                AllowOverride None
                Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch
                Require all granted
        </Directory>

	ErrorLog {$VHOSTS_DIR}/{$VHOST}/logs/error.log
	# Possible values include: debug, info, notice, warn, error, crit, alert, emerg.
	LogLevel warn
	CustomLog {$VHOSTS_DIR}/{$VHOST}/logs/access.log combined
</VirtualHost>

# ################################################################################## #
# Alias for http://{$HOSTNAME}/{$USER}
#           http://{$HOSTNAME}/{$VHOST_ONDOMAIN} 
#           http://{$HOSTNAME}/{$VHOST} 
# ################################################################################## #

Alias /{$USER} {$VHOSTS_DIR}/{$VHOST}/httpdocs
Alias /{$VHOST_ONDOMAIN} {$VHOSTS_DIR}/{$VHOST}/httpdocs
Alias /{$VHOST} {$VHOSTS_DIR}/{$VHOST}/httpdocs

<Directory /home/vhosts/www.sfs.it/httpdocs>
        AllowOverride FileInfo AuthConfig Limit Indexes
        Options MultiViews Indexes SymLinksIfOwnerMatch IncludesNoExec FollowSymLinks
        Require method GET POST OPTIONS
        Require all granted
</Directory>

