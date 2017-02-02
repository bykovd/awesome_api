AUTOTEST_PORT=3333
API_PORT=5000
API_AUTOTEST_PATH="/opt/autotest_api"
API_PATH="/opt/awesome_api/api"


echo "Copying .env file from development"
cp $API_PATH/.env $API_AUTOTEST_PATH/.env
echo "Changing enviroment to test"
sed  -i s/RACK_ENV=development/RACK_ENV=test/g $API_AUTOTEST_PATH/.env
echo "Adding port for test evniroment"

if grep PORT=$API_PORT $API_AUTOTEST_PATH/.env
then 
sed  -i s/PORT=$API_PORT/PORT=$AUTOTEST_PORT/g  $API_AUTOTEST_PATH/.env
else
echo "PORT=$AUTOTEST_PORT" >> $API_AUTOTEST_PATH/.env
fi

