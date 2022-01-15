#!/bin/bash

TEMP_PROCESS_FILE=temp_all_process.tmp

# SCRIPT STORAGE DIRECTORY
BASE_PATH=$(
  cd $(dirname $0)
  pwd
)

ps -ef | grep xxxxxxx | nl | awk -F ' ' '{print $3}' >$BASE_PATH/$TEMP_PROCESS_FILE

for pid in $(cat $BASE_PATH/$TEMP_PROCESS_FILE); do
  kill -9 $pid
done
