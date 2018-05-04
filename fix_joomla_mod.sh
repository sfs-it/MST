#!/bin/sh

if [ "$( uname )" = 'FreeBSD' ]; then
	CHMOD_OPTIONS=''
	CHOWN_OPTIONS=''
	WWW_USER='www'
	WWW_GROUP='www'
elif [ "$( uname )" = 'Linux' ]; then
	CHMOD_OPTIONS='-c'
	CHOWN_OPTIONS='-c'
	WWW_USER='$WWW_USER'
	WWW_GROUP='$WWW_USER'
fi

if [ "x$1" = "xDEVEL" ]; then
    chown $CHOWN_OPTIONS -R $WWW_USER .
    find . ! -type f -exec chmod $CHMOD_OPTIONS 770 '{}' \;
    find . -type f -exec chmod $CHMOD_OPTIONS 660 '{}' \;
    exit
fi
if [ "x$1" = "x" ]; then
        user="`whoami`"
else
        user="$1"
fi
echo 'FIX ALL FILES VHOST MOD'
find . ! -type f -exec chmod $CHMOD_OPTIONS 750 '{}' \;
echo 'FIX ALL DIRS VHOST MOD'
find . -type f -exec chmod $CHMOD_OPTIONS 640 '{}' \;
echo 'FIX ALL DIRS VHOST OWN'
find . -exec chown $CHOWN_OPTIONS "$user":$WWW_USER '{}' \;
if [ -d logs ]; then
	echo 'FIX logs/'
    chmod $CHMOD_OPTIONS -R 770 logs 
    chown $CHOWN_OPTIONS -R $WWW_USER:$WWW_GROUP logs 
elif [ ! -d administrator/logs ]; then
	echo 'CREATE administrator/logs/'
    mkdir administrator/logs
fi
if [ -d administrator/logs ]; then
	echo 'FIX administrator/logs/'
    chmod $CHMOD_OPTIONS -R 770 administrator/logs 
    chown $CHOWN_OPTIONS -R $WWW_USER:$WWW_GROUP administrator/logs 
fi
[ -d tmp ] || mkdir tmp
	echo 'FIX tmp'
chmod 770 tmp
chown -R $CHOWN_OPTIONS -R $WWW_USER:$WWW_GROUP tmp 
find tmp/* -type d -exec chmod $CHMOD_OPTIONS 770 {} \;
find tmp/* ! -type d -exec chmod $CHMOD_OPTIONS 660 {} \;
if [ -d cache ]; then
	echo 'FIX cache'
    chown -R $CHOWN_OPTIONS -R $WWW_USER:$WWW_GROUP cache
    chmod $CHOWN_OPTIONS 770 cache
    find cache/* -type d -exec chmod $CHMOD_OPTIONS 770 {} \;
    find cache/* ! -type d -exec chmod $CHMOD_OPTIONS 660 {} \;
	echo 'FIX administrator/cache/'
	chmod 770 administrator/cache
    chown -R $CHOWN_OPTIONS -R $WWW_USER:$WWW_GROUP administrator/cache
    find administrator/cache/* -type d -exec chmod $CHMOD_OPTIONS 770 {} \; -exec chown $CHOWN_OPTIONS -R  $WWW_USER:$WWW_GROUP {} \;
    find administrator/cache/* ! -type d -exec chmod $CHMOD_OPTIONS 660 {} \; -exec chown $CHOWN_OPTIONS -R  $WWW_USER:$WWW_GROUP {} \;
fi
#installation dir
if [ -d installation ]; then
	echo 'FIX installation'
    chmod 770 installation
    chown $CHOWN_OPTIONS -R $WWW_USER:$WWW_GROUP installation
    find installation/* -type d -exec chmod $CHMOD_OPTIONS 770 {} \;
    find installation/* ! -type d -exec chmod $CHMOD_OPTIONS 660 {} \;

fi

#aakeba backup data directory
if [ -d "administrator/components/com_akeeba/backup" ]; then
	echo 'FIX aakeba'
        chown $CHOWN_OPTIONS -R $WWW_USER administrator/components/com_akeeba/backup
        chmod $CHMOD_OPTIONS -R 770 administrator/components/com_akeeba/backup
fi
#galleries data directories
if [ -d "images/galleries/" ]; then
	echo 'FIX images/galleries/'
    chown $CHOWN_OPTIONS -R $WWW_USER images/galleries/
    find images/galleries/ ! -type f -exec chmod $CHMOD_OPTIONS 770 '{}' \;
    find images/galleries/ -type f -exec chmod $CHMOD_OPTIONS 660 '{}' \;
fi
#joomgallery data directories
if [ -d "images/joomgallery/" ]; then
	echo 'FIX images/joomgallery/'
    chown $CHOWN_OPTIONS -R $WWW_USER images/joomgallery/
    find images/joomgallery/ ! -type f -exec chmod $CHMOD_OPTIONS 770 '{}' \;
    find images/joomgallery/ -type f -exec chmod $CHMOD_OPTIONS 660 '{}' \;
fi
#vmart data directories
if [ -d "images/virtuemart" ]; then
	echo 'FIX images/virtuemart/'
    chown $CHOWN_OPTIONS -R $WWW_USER images/virtuemart/
    find images/virtuemart/ ! -type f -exec chmod $CHMOD_OPTIONS 770 '{}' \;
    find images/virtuemart/ -type f -exec chmod $CHMOD_OPTIONS 660 '{}' \;
fi
#com_easycreator data directories
if [ -d "components/com_easycreator" ]; then
	echo 'FIX components/com_easycreator'
    chown $CHOWN_OPTIONS -R $WWW_USER components/com_easycreator
    find components/com_easycreator ! -type f -exec chmod $CHMOD_OPTIONS 770 '{}' \;
    find components/com_easycreator -type f -exec chmod $CHMOD_OPTIONS 660 '{}' \;
	if [ -d "administrator/components/com_easycreator/data/" ]; then
		echo 'FIX administrator/components/com_easycreator/data/'
		chown $CHOWN_OPTIONS -R $WWW_USER administrator/components/com_easycreator/data/
		find administrator/components/com_easycreator/data/ ! -type f -exec chmod $CHMOD_OPTIONS 770 '{}' \;
		find administrator/components/com_easycreator/data/ -type f -exec chmod $CHMOD_OPTIONS 660 '{}' \;
	fi
fi
if [ -d "media/com_uniterevolution2" ]; then
	echo 'FIX media/com_uniterevolution2'
    chown $CHOWN_OPTIONS -R $WWW_USER media/com_uniterevolution2/assets/rs-plugin
    find media/com_uniterevolution2/assets/rs-plugin/ ! -type f -exec chmod $CHMOD_OPTIONS 770 '{}' \;
    find media/com_uniterevolution2/assets/rs-plugin/ -type f -exec chmod $CHMOD_OPTIONS 660 '{}' \;
fi
#component chronoforms 
if [ -d "libraries/cegcore2/cache" ]; then
	echo 'FIX libraries/cegcore2/cache'
    chown $CHOWN_OPTIONS -R $WWW_USER libraries/cegcore2/cache
    find libraries/cegcore2/cache ! -type f -exec chmod $CHMOD_OPTIONS 770 '{}' \;
    find libraries/cegcore2/cache -type f -exec chmod $CHMOD_OPTIONS 660 '{}' \;
fi
#component widgetkit
if [ -d "cache/widgetkit" ]; then
	echo 'FIX cache/widgetkit'
    chown $CHOWN_OPTIONS -R $WWW_USER cache/widgetkit
    find cache/widgetkit ! -type f -exec chmod $CHMOD_OPTIONS 770 '{}' \;
    find cache/widgetkit -type f -exec chmod $CHMOD_OPTIONS 660 '{}' \;
fi
