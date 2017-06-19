#!/bin/bash
set -e

if [ -z ${USER_UID+x} ]; then
        echo >&2 "Variable USER_UID is not set, skipping."
   else
        if [ $(id -u www-data) -ne 33 ]; then
                echo >&2 "UID and GID for www-data already modified, skipping."
           else
                : ${USER_GID:=${USER_UID}}
                usermod -u $USER_UID www-data
                groupmod -g $USER_GID www-data
                find / -user 33 2>/dev/null | xargs -r chown -h $USER_UID
                find / -group 33 2>/dev/null | xargs -r chgrp -h $USER_GID
                usermod -g www-data www-data
                echo >&2 "Ownership forced to new UID: $USER_UID and GID: $USER_GID."
        fi
fi

# Limit the prefork MPM
sed -i -e 's/\(.*\)\(StartServers\)\(.*\)/\1\2\t1/g' /etc/apache2/mods-enabled/mpm_prefork.conf
sed -i -e 's/\(.*\)\(MinSpareServers\)\(.*\)/\1\2\t1/g' /etc/apache2/mods-enabled/mpm_prefork.conf
sed -i -e 's/\(.*\)\(MaxSpareServers\)\(.*\)/\1\2\t3/g' /etc/apache2/mods-enabled/mpm_prefork.conf
sed -i -e 's/\(.*\)\(MaxRequestWorkers\)\(.*\)/\1\2\t15/g' /etc/apache2/mods-enabled/mpm_prefork.conf
sed -i -e 's/\(.*\)\(MaxConnectionsPerChild\)\(.*\)/\1\2\t250/g' /etc/apache2/mods-enabled/mpm_prefork.conf

exec "$@"
