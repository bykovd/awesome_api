#!/bin/bash

AUTOTEST_PORT=3333
API_PORT=5000
API_AUTOTEST_PATH="/opt/autotest_api"
API_PATH="/opt/awesome_api/api"

exit 0

cd $API_AUTOTEST_PATH ; /usr/local/rvm/gems/ruby-2.3.0/bin/foreman start  >> $API_AUTOTEST_PATH/api.log 2>&1  &
echo $! > $API_AUTOTEST_PATH/api.pid

sleep 3

curl $( ip addr list eth0 |grep "inet " |cut -d' ' -f6|cut -d/ -f1):$AUTOTEST_PORT/ticks | awk '{print $2}' | awk -F "<" '{print $1}' > $API_AUTOTEST_PATH/initial_ticks_number.txt

curl -X POST $( ip addr list eth0 |grep "inet " |cut -d' ' -f6|cut -d/ -f1):$AUTOTEST_PORT/ticks
sleep 5
curl -X POST $( ip addr list eth0 |grep "inet " |cut -d' ' -f6|cut -d/ -f1):$AUTOTEST_PORT/ticks
sleep 5
curl -X POST $( ip addr list eth0 |grep "inet " |cut -d' ' -f6|cut -d/ -f1):$AUTOTEST_PORT/ticks
sleep 5

sleep 20
curl $( ip addr list eth0 |grep "inet " |cut -d' ' -f6|cut -d/ -f1):$AUTOTEST_PORT/ticks | awk '{print $2}' | awk -F "<" '{print $1}' > $API_AUTOTEST_PATH/final_ticks_number.txt


kill $(cat $API_AUTOTEST_PATH/api.pid)




FINAL=`cat $API_AUTOTEST_PATH/final_ticks_number.txt`
INITIAL=`cat $API_AUTOTEST_PATH/initial_ticks_number.txt`




if [ "$FINAL" -gt "$INITIAL" ]
#if [ "$FINAL" -qt "$INITIAL" ]
then
echo "Autotest passed successfully Old value: $INITIAL, Current value $FINAL"
exit 0
else
echo "Autotest failed. There are no new ticks. Old value: $INITIAL, Current value $FINAL"
exit 2
fi



