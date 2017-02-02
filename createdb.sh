#!/bin/bash

PG_DB=`cat /opt/evn_details.txt  | grep PG_DB  | awk -F "=" '{print $2}'`
PG_ADMIN_PASSWORD=`cat /opt/evn_details.txt  | grep PG_ADMIN_PASSWORD  | awk -F "=" '{print $2}'`
PG_ADMIN_USER=`cat /opt/evn_details.txt  | grep PG_ADMIN_USER  | awk -F "=" '{print $2}'`
PG_ENDPOINT=`cat /opt/evn_details.txt  | grep PG_ENDPOINT  | awk -F "=" '{print $2}'`
API_DB_USER_PASSWORD=`cat /opt/evn_details.txt  | grep API_DB_USER_PASSWORD  | awk -F "=" '{print $2}'`
API_DB_USERNAME=`cat /opt/evn_details.txt  | grep API_DB_USERNAME  | awk -F "=" '{print $2}'`


if export PGPASSWORD="$PG_ADMIN_PASSWORD"; /usr/bin/psql -h $PG_ENDPOINT -U $PG_ADMIN_USER  -d $PG_DB -c "\l" | grep -q my_api_development
then
echo "Database my_api_development already exist. Skipping database creation" >>  /opt/bootstrap.log
else
echo "Creating database my_api_development" >>  /opt/bootstrap.log
export PGPASSWORD="$PG_ADMIN_PASSWORD"; /usr/bin/psql -h $PG_ENDPOINT -U $PG_ADMIN_USER  -d $PG_DB -c "CREATE DATABASE my_api_development;" >> /opt/bootstrap.log 2>&1
fi

if export PGPASSWORD="$PG_ADMIN_PASSWORD"; /usr/bin/psql -h $PG_ENDPOINT -U $PG_ADMIN_USER  -d $PG_DB -c "\l" | grep -q my_api_test
then
echo "Database my_api_test already exist. Skipping database creation" >>  /opt/bootstrap.log
else
echo "Creating database my_api_test" >>  /opt/bootstrap.log
export PGPASSWORD="$PG_ADMIN_PASSWORD"; /usr/bin/psql -h $PG_ENDPOINT -U $PG_ADMIN_USER  -d $PG_DB -c "CREATE DATABASE my_api_test;" >> /opt/bootstrap.log 2>&1
fi

echo "Creating DBuser" >>  /opt/bootstrap.log
export PGPASSWORD="$PG_ADMIN_PASSWORD"; /usr/bin/psql -h $PG_ENDPOINT -U $PG_ADMIN_USER  -d $PG_DB -c "CREATE USER $API_DB_USERNAME WITH password '$API_DB_USER_PASSWORD';" >> /opt/bootstrap.log 2>&1
export PGPASSWORD="$PG_ADMIN_PASSWORD"; /usr/bin/psql -h $PG_ENDPOINT -U $PG_ADMIN_USER  -d $PG_DB -c "GRANT ALL privileges ON DATABASE my_api_development TO $API_DB_USERNAME;" >> /opt/bootstrap.log 2>&1
export PGPASSWORD="$PG_ADMIN_PASSWORD"; /usr/bin/psql -h $PG_ENDPOINT -U $PG_ADMIN_USER  -d $PG_DB -c "GRANT ALL privileges ON DATABASE my_api_test TO $API_DB_USERNAME;" >> /opt/bootstrap.log 2>&1
