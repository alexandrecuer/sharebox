#!/command/with-contenv sh
while ! pg_isready; do
    sleep 1
done

echo "postgresql running..."

if [ "$NEW_INSTALL" -eq 1 ]; then
    echo "creating $DB_USER_NAME user"
    /exec_cmd.sh create_role
fi
