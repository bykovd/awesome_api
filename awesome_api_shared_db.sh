#!/bin/bash
sudo apt-get update
sudo apt-get -y install git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev python-software-properties libffi-dev nodejs libpq-dev postgresql-client mc python-pip
HOSTNAME=`hostname`; echo "127.0.0.1 $HOSTNAME" >> /etc/hosts
mkdir /opt/awesome_api

curl -L https://get.rvm.io | bash -s stable --rails --autolibs=enabled
source /usr/local/rvm/scripts/rvm
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3	
rvm get stable --auto-dotfiles
rvm install 2.3.0

git clone https://github.com/door2door-io/systems-engineer-challenge.git /opt/awesome_api
cd /opt/awesome_api/api/
gem install bundler
bundle install
gem install foreman

/opt/bootstrap/createdb.sh

REDIS_ENDPOINT=`cat /opt/redis_endoint.txt`
PG_ENDPOINT=`cat /opt/pg_endoint.txt`
API_DB_USER_PASSWORD=`cat /opt/evn_details.txt  | grep API_DB_USER_PASSWORD  | awk -F "=" '{print $2}'`
API_DB_USERNAME=`cat /opt/evn_details.txt  | grep API_DB_USERNAME  | awk -F "=" '{print $2}'`




cat <<EOF > /opt/awesome_api/api/.env
DATABASE_URL=$API_DB_USERNAME:$API_DB_USER_PASSWORD@$PG_ENDPOINT:5432/my_api_development
RACK_ENV=test
REDIS_PUBLISH_URL=redis://$REDIS_ENDPOINT/0
RDS_DB_NAME=my_api_development
RDS_HOSTNAME=$PG_ENDPOINT
RDS_PASSWORD=$API_DB_USER_PASSWORD
RDS_PORT=5432
RDS_USERNAME=$API_DB_USERNAME
TEST_DATABASE_URL=$API_DB_USERNAME:$API_DB_USER_PASSWORD@$PG_ENDPOINT:5432/my_api_test
EOF

cat <<EOF > /opt/awesome_api/api/db/setup.rb
require "sequel"
require "aws-sdk"
require "redis"
require "sidekiq"
DB ||= if ENV["RACK_ENV"] == "test"
         Sequel.connect('postgres://$API_DB_USERNAME:$API_DB_USER_PASSWORD@$PG_ENDPOINT/my_api_test')
       elsif ENV.key?("RDS_HOSTNAME")
         Sequel.connect('postgres://$API_DB_USERNAME:$API_DB_USER_PASSWORD@$PG_ENDPOINT/my_api_development')
       else
         Sequel.connect('postgres://$API_DB_USERNAME:$API_DB_USER_PASSWORD@$PG_ENDPOINT/my_api_development')
       end
Sidekiq.configure_server do |config|
  config.redis = { url: 'redis://$REDIS_ENDPOINT:6379/0' }
end
EOF

sed -i s/"127.0.0.1"/"$REDIS_ENDPOINT"/g /usr/local/rvm/gems/ruby-2.3.0/gems/redis-3.3.1/lib/redis/client.rb

foreman run bundle exec rake  db:migrate
foreman run bundle exec rake db:migrate RACK_ENV=test

rvm cron setup
echo "To check current ticks number run: curl $( ip addr list eth0 |grep "inet " |cut -d' ' -f6|cut -d/ -f1):5000/ticks" >> /opt/awesome_api/api/api.log
echo "To continuosly check current ticks number run: while true; do  curl 192.168.2.93:5000/ticks;   echo -e "\n" ; sleep 5 ; done" >> /opt/awesome_api/api/api.log
echo "To add new ticks run:   curl -X POST $( ip addr list eth0 |grep "inet " |cut -d' ' -f6|cut -d/ -f1):5000/ticks" >> /opt/awesome_api/api/api.log


cat <<EOF  >> /var/spool/cron/crontabs/root
@reboot cd  /opt/awesome_api/api/ ; /usr/local/rvm/gems/ruby-2.3.0/bin/foreman start  >> /opt/awesome_api/api/api.log 2>&1  &

EOF

cd /opt/awesome_api/api/ ; /usr/local/rvm/gems/ruby-2.3.0/bin/foreman start  >> /opt/awesome_api/api/api.log 2>&1  &


cat <<EOF > /opt/awesome_api/api/awesome_api_daemon.sh
#!/bin/bash

PORT="0.0.0.0:5000"

function start {
if [ -f /opt/awesome_api/api/api.pid ]
then
    if  netstat  -ntlupa |  grep -q \$PORT
        then
        echo "Daemon is already running"
        exit 2
        else
        echo "Starting daemon"
        cd /opt/awesome_api/api/ ; /usr/local/rvm/gems/ruby-2.3.0/bin/foreman start  >> /opt/awesome_api/api/api.log 2>&1  &
        echo \$! > /opt/awesome_api/api/api.pid
        fi
else
echo "Process pid not exist"
    if  netstat  -ntlupa |  grep -q \$PORT
        then
        echo "Port \$PORT is busy"
        echo "Can't start daemon"
        else
        echo "Port \$PORT available"
        echo "Starting daemon"
        cd /opt/awesome_api/api/ ; /usr/local/rvm/gems/ruby-2.3.0/bin/foreman start  >> /opt/awesome_api/api/api.log 2>&1  &
        echo \$! > /opt/awesome_api/api/api.pid
        fi
fi
}

function stop {
if [ -f /opt/awesome_api/api/api.pid ]
then
echo "Process pid exist"
echo "Checking if port is oppened"
    if  netstat  -ntlupa |  grep -q \$PORT
        then
        echo "Port \$PORT is busy"
        echo "Stoppping daemon"
        kill \$(cat /opt/awesome_api/api/api.pid)
        rm /opt/awesome_api/api/api.pid
        else
        echo "Port \$PORT is not busy"
        echo "Daemon is not running"
        exit 1
    fi
else
echo "Process pid not exist"
    if  netstat  -ntlupa |  grep -q \$PORT
        then
        echo "Port \$PORT is busy"
        echo "Stop daemon manually"
        else
        echo "Port \$PORT available"
        echo "Daemon is not running"
    fi
fi
}

case "\$1" in
  start)
        start
    ;;
  stop)
        stop
    ;;
  *)
    echo "Usage: {start|stop}"
    exit 1
    ;;
esac

EOF

chmod  a+x /opt/awesome_api/api/awesome_api_daemon.sh

cd /opt/install/ ;
wget https://aws-codedeploy-eu-west-1.s3.amazonaws.com/latest/install
chmod +x ./install
./install auto

