# SCRIPT STORAGE DIRECTORY
BASE_PATH=$(
  cd $(dirname $0)
  pwd
)

echo ">>>>>> Copy the following commands into crontab >>>>>>"
echo "*/1 * * * *" flock -xn $BASE_PATH/convert65/lock.lock -c "\"bash $BASE_PATH/convert65/convert_65.sh >> $BASE_PATH/convert65/crontab.log 2>&1\""
