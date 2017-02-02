AUTOTEST_PORT=3333
API_PORT=5000
API_AUTOTEST_PATH="/opt/autotest_api"
API_PATH="/opt/awesome_api/api"


mkdir -p $API_AUTOTEST_PATH/
rm -rf  $API_AUTOTEST_PATH/*
rm -f API_AUTOTEST_PATH/.env
echo "stop api" >> /opt/test_api/testing.log

if  netstat  -ntlupa |  grep -q $AUTOTEST_PORT
        then
        echo "Test daemon is already running" >> /opt/test_api/testing.log
        exit 2
        else
        echo "Starting deploying autotest"

fi
