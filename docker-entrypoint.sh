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

tee /etc/apache2/sites-enabled/000-default.conf <<'EOF'
<VirtualHost *:80>
        # The ServerName directive sets the request scheme, hostname and port that
        # the server uses to identify itself. This is used when creating
        # redirection URLs. In the context of virtual hosts, the ServerName
        # specifies what hostname must appear in the request's Host: header to
        # match this virtual host. For the default virtual host (this file) this
        # value is not decisive as it is used as a last resort host regardless.
        # However, you must set it for any further virtual host explicitly.
        #ServerName www.example.com
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/html
        # Available loglevels: trace8, ..., trace1, debug, info, notice, warn,
        # error, crit, alert, emerg.
        # It is also possible to configure the loglevel for particular
        # modules, e.g.
        #LogLevel info ssl:warn
	LogFormat "%h %l %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\"" combined
        LogFormat "%{X-Forwarded-For}i %l %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\"" proxy
        SetEnvIf X-Forwarded-For "^.*\..*\..*\..*" forwarded
	ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined env=!forwarded
        CustomLog ${APACHE_LOG_DIR}/access.log proxy env=forwarded
        # For most configuration files from conf-available/, which are
        # enabled or disabled at a global level, it is possible to
        # include a line for only one particular virtual host. For example the
        # following line enables the CGI configuration for this host only
        # after it has been globally disabled with "a2disconf".
        #Include conf-available/serve-cgi-bin.conf
</VirtualHost>
EOF

exec "$@"
