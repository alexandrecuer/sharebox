#!/command/with-contenv sh

cp "/usr/share/zoneinfo/$TZ" /etc/localtime

NEW_INSTALL=0

if ! [ -d "/data/pgsql" ]; then
    echo "Creating postgresql database"
    NEW_INSTALL=1
    mkdir -p /data/pgsql
    chown postgres /data/pgsql
    /exec_cmd.sh initdb
else
    echo "Using existing postgresql database"
fi

printf "Fixing NEW_INSTALL=$NEW_INSTALL in the ENV\n"
printf "%s" $NEW_INSTALL > /var/run/s6/container_environment/NEW_INSTALL
