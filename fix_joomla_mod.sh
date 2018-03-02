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
find . ! -type f -exec chmod $CHMOD_OPTIONS 750 '{}' \;
find . -type f -exec chmod $CHMOD_OPTIONS 640 '{}' \;
find . -exec chown $CHOWN_OPTIONS "$user":$WWW_USER '{}' \;
chmod $CHMOD_OPTIONS -R 770 logs 
chown $CHOWN_OPTIONS -R $WWW_USER:$WWW_GROUP logs 
find . -name "tmp" -type d -exec chmod $CHMOD_OPTIONS -R 770 {} \; -exec chown $CHOWN_OPTIONS -R $WWW_USER:$WWW_GROUP {} \;
find . -name "cache" -type d -exec chmod $CHMOD_OPTIONS -R 770 {} \; -exec chown $CHOWN_OPTIONS -R $WWW_USER:$WWW_GROUP {} \;
find tmp/* -type d -exec chmod $CHMOD_OPTIONS -R 770 {} \; -exec -R -c chown $CHOWN_OPTIONS $WWW_USER:$WWW_GROUP {} \;
find cache/* -type d -exec chmod $CHMOD_OPTIONS -R 770 {} \; -exec chown $CHOWN_OPTIONS -R  $WWW_USER:$WWW_GROUP {} \;
#aakeba backup data directory
if [ -d "administrator/components/com_akeeba/backup" ]; then
        chown $CHOWN_OPTIONS -R $WWW_USER administrator/components/com_akeeba/backup
        chmod $CHMOD_OPTIONS -R 770 administrator/components/com_akeeba/backup
fi
#galleries data directories
if [ -d "images/galleries/" ]; then
    chown $CHOWN_OPTIONS -R $WWW_USER images/galleries/
    find images/galleries/ ! -type f -exec chmod $CHMOD_OPTIONS 770 '{}' \;
    find images/galleries/ -type f -exec chmod $CHMOD_OPTIONS 660 '{}' \;
fi
#joomgallery data directories
if [ -d "images/joomgallery/" ]; then
    chown $CHOWN_OPTIONS -R $WWW_USER images/joomgallery/
    find images/joomgallery/ ! -type f -exec chmod $CHMOD_OPTIONS 770 '{}' \;
    find images/joomgallery/ -type f -exec chmod $CHMOD_OPTIONS 660 '{}' \;
fi
#vmart data directories
if [ -d "images/virtuemart" ]; then
    chown $CHOWN_OPTIONS -R $WWW_USER images/virtuemart/
    find images/virtuemart/ ! -type f -exec chmod $CHMOD_OPTIONS 770 '{}' \;
    find images/virtuemart/ -type f -exec chmod $CHMOD_OPTIONS 660 '{}' \;
fi
#com_easycreator data directories
if [ -d "components/com_easycreator" ]; then
    chown $CHOWN_OPTIONS -R $WWW_USER components/com_easycreator
    find components/com_easycreator ! -type f -exec chmod $CHMOD_OPTIONS 770 '{}' \;
    find components/com_easycreator -type f -exec chmod $CHMOD_OPTIONS 660 '{}' \;
fi
if [ -d "administrator/components/com_easycreator/data/" ]; then
    chown $CHOWN_OPTIONS -R $WWW_USER administrator/components/com_easycreator/data/
    find administrator/components/com_easycreator/data/ ! -type f -exec chmod $CHMOD_OPTIONS 770 '{}' \;
    find administrator/components/com_easycreator/data/ -type f -exec chmod $CHMOD_OPTIONS 660 '{}' \;
fi
if [ -d "media/com_uniterevolution2" ]; then
    chown $CHOWN_OPTIONS -R $WWW_USER media/com_uniterevolution2/assets/rs-plugin
    find media/com_uniterevolution2/assets/rs-plugin/ ! -type f -exec chmod $CHMOD_OPTIONS 770 '{}' \;
    find media/com_uniterevolution2/assets/rs-plugin/ -type f -exec chmod $CHMOD_OPTIONS 660 '{}' \;
fi
#component chronoforms 
if [ -d "libraries/cegcore2/cache" ]; then
    chown $CHOWN_OPTIONS -R $WWW_USER libraries/cegcore2/cache
    find libraries/cegcore2/cache ! -type f -exec chmod $CHMOD_OPTIONS 770 '{}' \;
    find libraries/cegcore2/cache -type f -exec chmod $CHMOD_OPTIONS 660 '{}' \;
fi
#component widgetkit
if [ -d "cache/widgetkit" ]; then
    chown $CHOWN_OPTIONS -R $WWW_USER cache/widgetkit
    find cache/widgetkit ! -type f -exec chmod $CHMOD_OPTIONS 770 '{}' \;
    find cache/widgetkit -type f -exec chmod $CHMOD_OPTIONS 660 '{}' \;
fi
