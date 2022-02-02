#!/bin/bash
### BEGIN DESCRIPTION
#
# Required Tool:
# -> curl, zip, xmllint, pwd, mkdir, touch, cat, sed, grep, awk, rm, aws
#
# Need to install Tool:
# -> zip, xmllint, aws, curl
#
### END DESCRIPTION

## xml data sources
#readonly XML_URL=http://54.92.43.67:7771/res.xml
#
## aem server info for (upload, build, download)
#readonly USER63="admin"
#readonly PASSWORD63="adminadmin"
#readonly IP63="54.92.43.67"
#readonly PORT63=7769
## aws s3
#readonly AWS_S3_PATH="s3://oss-zhghx"

# SYSTEM CONFIG
readonly CONFIG_INI=config.ini
readonly TEMP_FILE_ALL=temp_all.xml
readonly TEMP_FILE_ITEM=temp_item.xml
readonly ALL_PACKAGE_IFNO_XML=all_package.xml
readonly FILTER_FILE=filter.xml
readonly PROPERTIES_FILE=properties.xml
readonly AEM_ZIP_FOLDER=pre_build_zip
readonly AEM_LOG_FOLDER=logs
readonly AEM_DOWNLOAD_FOLDER=download_build_done_zip
readonly GROUP_NAME=shell_upload_group

# SCRIPT STORAGE DIRECTORY
BASE_PATH=$(
  cd $(dirname $0)
  pwd
)

# CHECK CONFIG
if [ ! -f "$BASE_PATH/$CONFIG_INI" ]; then
  echo 'Error: [config.ini] is not find.' >&2
  exit 1
fi
if [ ! -s "$BASE_PATH/$CONFIG_INI" ]; then
  echo 'Error: [config.ini] is empty.' >&2
  exit 1
fi

# xml data sources
readonly XML_URL=$(cat $BASE_PATH/$CONFIG_INI | awk '{if($0~"XML_URL") print}' | awk -F '=' '{print $2}')
# aem server info for (upload, build, download)
readonly USER63=$(cat $BASE_PATH/$CONFIG_INI | awk '{if($0~"AEM_USER") print}' | awk -F '=' '{print $2}')
readonly PASSWORD63=$(cat $BASE_PATH/$CONFIG_INI | awk '{if($0~"AEM_PASSWORD") print}' | awk -F '=' '{print $2}')
readonly IP63=$(cat $BASE_PATH/$CONFIG_INI | awk '{if($0~"AEM_IP") print}' | awk -F '=' '{print $2}')
readonly PORT63=$(cat $BASE_PATH/$CONFIG_INI | awk '{if($0~"AEM_PORT") print}' | awk -F '=' '{print $2}')
readonly AWS_S3_PATH=$(cat $BASE_PATH/$CONFIG_INI | awk '{if($0~"AWS_S3_PATH") print}' | awk -F '=' '{print $2}')
readonly PACKAGE_VERSION=$(cat $BASE_PATH/$CONFIG_INI | awk '{if($0~"PACKAGE_VERSION") print}' | awk -F '=' '{print $2}')

# CHECK CONFIG
if [[ $XML_URL == "" ]]; then
  echo 'Error: [config.ini] XML_URL is not find.' >&2
  exit 1
fi
if [[ $USER63 == "" ]]; then
  echo 'Error: [config.ini] USER63 is not find.' >&2
  exit 1
fi
if [[ $IP63 == "" ]]; then
  echo 'Error: [config.ini] IP63 is not find.' >&2
  exit 1
fi
if [[ $PORT63 == "" ]]; then
  echo 'Error: [config.ini] PORT63 is not find.' >&2
  exit 1
fi

# CHECK COMMAND
if [ ! -x "$(command -v curl)" ]; then
  echo 'Error: curl is not installed.' >&2
  exit 1
fi
if [ ! -x "$(command -v zip)" ]; then
  echo 'Error: zip is not installed.' >&2
  exit 1
fi
if [ ! -x "$(command -v xmllint)" ]; then
  echo 'Error: xmllint is not installed.' >&2
  exit 1
fi
if [ ! -x "$(command -v aws)" ]; then
  echo 'Error: aws is not installed.' >&2
  exit 1
fi

#######################################
############### READY #################
#######################################
# GET XML FILE
if [ ! -f "$BASE_PATH/$TEMP_FILE_ALL" ]; then
  curl -s -u $USER63:$PASSWORD63 $XML_URL >$BASE_PATH/$TEMP_FILE_ALL
fi
# XML FILE UPLOAD S3
aws s3 cp "$BASE_PATH/$TEMP_FILE_ALL" "$AWS_S3_PATH/"

# CHECK ZIP FOLDER
if [ -d "$BASE_PATH/$AEM_ZIP_FOLDER" ]; then
  rm -rf $BASE_PATH/$AEM_ZIP_FOLDER
fi

## CHECK LOG FOLDER
#if [ -d "$BASE_PATH/$AEM_LOG_FOLDER" ]; then
#  rm -rf $BASE_PATH/$AEM_LOG_FOLDER
#fi
#
## CHECK DOWNLOAD FOLDER
#if [ -d "$BASE_PATH/$AEM_DOWNLOAD_FOLDER" ]; then
#  rm -rf $BASE_PATH/$AEM_DOWNLOAD_FOLDER
#fi

#######################################
###############  START  ###############
############ LOOP GET ITEM ############
#######################################

echo "[*]======================================================"
echo "[*]===================== Start =========================="
echo "[*]======================================================"

for ((i = 1; 1; i++)); do

  # GET ITEM BY XMLLINT
  xmllint --xpath "//channel/item[$i]" $BASE_PATH/$TEMP_FILE_ALL >$BASE_PATH/$TEMP_FILE_ITEM

  ITEM_RESULT=$(cat $BASE_PATH/$TEMP_FILE_ITEM)
  if [[ $ITEM_RESULT == "" ]]; then
    echo -e "\n[*]ITEM READ END, READY TO BUILD ...\n"
    break
  fi

  xmllint --format $BASE_PATH/$TEMP_FILE_ITEM
 
  echo -e "\n"

done

# DELETE TEMP FILE
rm -rf "$BASE_PATH/$TEMP_FILE_ITEM"

echo "[*]!!! Test Success !!!"
