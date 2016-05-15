#!/bin/bash

# Function to update the fpm configuration to make the service environment variables available
function setEnvironmentVariable {
    if [ -z "$2" ]; then
            echo "Environment variable '$1' not set."
            return
    fi

    # Check whether variable already exists
    if grep -q $1 /etc/php/fpm/env.conf; then
        # Reset variable
        sed -i "s/^env\[$1.*/env[$1] = $2/g" /etc/php/fpm/env.conf
    else
        # Add variable
        echo "env[$1] = $2" >> /etc/php/fpm/env.conf
    fi
}

function changeNginxEnvVars {
    if [ -z "$2" ]; then
            echo "Environment variable '$1' not set."
            return
    fi

    echo "Replacing {$1} for $2 on /etc/nginx/sites-available/default"

    sed -i "s/{$1}/$2/g" /etc/nginx/sites-available/default
}

function phpcliEnvVars {
    if [ -z "$2" ]; then
            echo "Environment variable '$1' not set."
            return
    fi

    # Check whether variable already exists
    if grep -q $1 /srv/www/config/env.php; then
        # Reset variable
        sed -i "s/^putenv\('$1.*/putenv('$1=$2');/g" /srv/www/config/env.php
    else
        # Add variable
        echo "putenv('$1=$2');" >> /srv/www/config/env.php
    fi
}

echo "<?php
" > /srv/www/config/env.php


# Grep for variables that look like MySQL (MYSQL)
for _curVar in `env | awk -F = '{print $1}'`;do
    # awk has split them by the equals sign
    # Pass the name and value to our function
    setEnvironmentVariable ${_curVar} ${!_curVar}
    phpcliEnvVars ${_curVar} ${!_curVar}
done

for _curVar in `env | awk -F = '{print $1}'`;do
    # awk has split them by the equals sign
    # Pass the name and value to our function
    changeNginxEnvVars ${_curVar} ${!_curVar}
done

# publish assets & run migrations
/srv/www/yii migrate/up --interactive=0

# start php-fpm and nginx
crond -l 2
php-fpm
exec nginx
