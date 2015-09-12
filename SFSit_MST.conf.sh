#!/bin/sh
# COPY THIS FILE TO /etc/SFS.it_MST.conf or on /root/SFS.it_MST.conf

# SYSTEM SETTINGS
HOSTNAME='yourhost.fqdn.local'		# YOUR FQDN hostname
VHOSTS_DIR='/home/vhosts'		# WHERE VHOST ARE STORED
HTTPDOCS_DIR='httpdocs'			# VHOST httpdocs directory
HTTPLOGS_DIR='logs'			# VHOST httplogs directory
WWW_GROUP='www-data'			# www-group (on ubuntu www-data on apache2
APACHE_CONF='SAVE'			# SAVE APACHE CONFIGURATION ON CREATE VHOST
SAMBA_CONF='SAVE'			# SAVE SAMBA CONFIGURATION ON CREATE VHOST
MYSQL_ROOT_PWD='ROOTPWD'		# MySQL root password

# MAILNG SETTINGS
ADMIN_EMAIL='admin@email.QDN'		# Default email who send email
HOST_EMAIL='host@email.QDN'		# Default email sender
MY_DOMAIN='QDN'				# mydomanin.local

# GRIVE AND RSYNC
GRIVE_EMAIL='ACCOUNT@gmail.com'		# account enabled for grive sync tool
GRIVE_DIR='/home/vhosts/gDrive'		# directory where gDrive is synced
GRIVE_DIR_SUBDIR_BACKUP="backups"	# subdir on gDrive dir for backups
GRIVE_DIR_SUBDIR_RSYNC="rsync"		# subdir for rsync

# LORG CONFIG
LORG_DIR='/usr/share/php/lorg'		# lorg installation directory 
					#  to install:
					#	cd /usr/share/php/ 
					#	git clone https://github.com/jensvoid/lorg
LORG_OPT=' -i combined -o html -d phpids -d chars  -a all -c all -b all -t 10 -v 2 -h -g -p'
		# ' -i combined -o html -d phpids -d chars -d dnsbl -a all -c all -b all -t 10 -v 2 -h -g -p'
LORG_SAVE_REPORT_ON_HTTPDOC_SLOGS="false"
LORG_SPLITTED="false"
LORG_ATTACH_REPORT="false"


if [ "x$(basename $0)" = "xSFSit_MST.conf.sh" ]
        key="$(echo "$1"|tr '[:lower:]' '[:upper:]')"
        eval "echo \$$key"
fi