#!/command/with-contenv sh
if [ "$1" = "initdb" ]; then
    exec s6-setuidgid postgres initdb -D /data/pgsql
fi

if [ "$1" = "create_role" ]; then
    exec s6-setuidgid postgres psql -c "CREATE ROLE $DB_USER_NAME PASSWORD '$DB_USER_PASS' CREATEDB LOGIN;"
fi

