#!/bin/sh
if [ "x$1" = "xDEVEL" ]; then
    chown -c -R www-data .
    find . ! -type f -exec chmod -c 770 '{}' \;
    find . -type f -exec chmod -c 660 '{}' \;
    exit
fi
if [ "x$1" = "x" ]; then
        user="`whoami`"
else
        user="$1"
fi

find . ! -type f -exec chmod -c 750 '{}' \;
find . -type f -exec chmod -c 640 '{}' \;
find . -exec chown "$user":www-data '{}' \;
chmod -R -c 770 logs 
chown -R -c www-data:www-data logs 
find . -name "tmp" -type d -exec chmod -R -c 770 {} \; -exec -R -c www-data:www-data {} \;
find . -name "cache" -type d -exec chmod -R -c 770 {} \; -exec -R -c www-data:www-data {} \;
find tmp/* -type d -exec chmod -R -c 770 {} \; -exec -R -c www-data:www-data {} \;
find cache/* -type d -exec chmod -R -c 770 {} \; -exec -R -c www-data:www-data {} \;
#aakeba backup data directory
if [ -d "administrator/components/com_akeeba/backup" ]; then
        chown -c -R www-data administrator/components/com_akeeba/backup
        chmod -c -R 770 administrator/components/com_akeeba/backup
fi
#galleries data directories
if [ -d "images/galleries/" ]; then
    chown -c -R www-data images/galleries/
    find images/galleries/ ! -type f -exec chmod -c 770 '{}' \;
    find images/galleries/ -type f -exec chmod -c 660 '{}' \;
fi
#joomgallery data directories
if [ -d "images/joomgallery/" ]; then
    chown -c -R www-data images/joomgallery/
    find images/joomgallery/ ! -type f -exec chmod -c 770 '{}' \;
    find images/joomgallery/ -type f -exec chmod -c 660 '{}' \;
fi
#vmart data directories
if [ -d "images/virtuemart" ]; then
    chown -c -R www-data images/virtuemart/
    find images/virtuemart/ ! -type f -exec chmod -c 770 '{}' \;
    find images/virtuemart/ -type f -exec chmod -c 660 '{}' \;
fi
#com_easycreator data directories
if [ -d "components/com_easycreator" ]; then
    chown -c -R www-data components/com_easycreator
    find components/com_easycreator ! -type f -exec chmod -c 770 '{}' \;
    find components/com_easycreator -type f -exec chmod -c 660 '{}' \;
fi
if [ -d "administrator/components/com_easycreator/data/" ]; then
    chown -c -R www-data administrator/components/com_easycreator/data/
    find administrator/components/com_easycreator/data/ ! -type f -exec chmod -c 770 '{}' \;
    find administrator/components/com_easycreator/data/ -type f -exec chmod -c 660 '{}' \;
fi

