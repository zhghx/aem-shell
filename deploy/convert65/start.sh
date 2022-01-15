#!/bin/sh

PID_FILE=aem_move_convert.pid

# SCRIPT STORAGE DIRECTORY
BASE_PATH=$(
  cd $(dirname $0)
  pwd
)

nohup bash $BASE_PATH/convert_65.sh &
echo $! >$PID_FILE
