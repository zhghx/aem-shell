#!/bin/bash

rm -rf ./convert65
mkdir ./convert65
touch ./convert65/lock.lock
aws s3 cp s3://vx-tokyo/tmp/tei_work/prod_author_content_v1/convert65/config.ini ./convert65/
aws s3 cp s3://vx-tokyo/tmp/tei_work/prod_author_content_v1/convert65/convert_65.sh ./convert65/

# SCRIPT STORAGE DIRECTORY
BASE_PATH=$(
  cd $(dirname $0)
  pwd
)

echo ">>>>>> Copy the following commands into crontab >>>>>>"
echo "*/1 * * * *" flock -xn $BASE_PATH/convert65/lock.lock -c "\"bash $BASE_PATH/convert65/convert_65.sh >> $BASE_PATH/convert65/crontab.log 2>&1\""
