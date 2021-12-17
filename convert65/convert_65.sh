#!/bin/bash

### BEGIN DESCRIPTION
#
# Required Tool:
# -> curl, zip, xmllint, pwd, mkdir, touch, cat, sed, grep, awk, rm, aws
#
# Need to install Tool:
# -> zip, xmllint, aws, curl
#
# crontab:
# crontab -e, crontab -l
# -> */1 * * * * bash /Users/xxx/CODE/aem-custom/shell/convert_65.sh >> /Users/xxx/CODE/aem-custom/shell/crontab.log 2>&1
#
### END DESCRIPTION

#AWS_CLI_PATH=/System/Volumes/Data/opt/homebrew/bin/

# aws-cli PATH; * crontab not find aws *
# export PATH=$AWS_CLI_PATH:$PATH

# SYSTEM CONFIG
readonly CONFIG_INI=config.ini
readonly TEMP_FILE_ALL=temp_all.xml
readonly TEMP_FILE_ITEM=temp_item.xml
readonly ALL_PACKAGE_IFNO_XML=all_package.xml
readonly FILTER_FILE=filter.xml
readonly PROPERTIES_FILE=properties.xml
readonly AEM_ZIP_FOLDER=pre_build_zip
readonly AEM_LOG_FOLDER=logs
readonly AEM_DOWNLOAD_FOLDER=download_s3_to_65_zip
readonly GROUP_NAME=shell_upload_group
readonly PACKAGE_VERSION=$(date +%Y%m%d)
readonly CONVERT_LOCK=convert.lock

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
readonly USER65=$(cat $BASE_PATH/$CONFIG_INI | awk '{if($0~"AEM_USER") print}' | awk -F '=' '{print $2}')
readonly PASSWORD65=$(cat $BASE_PATH/$CONFIG_INI | awk '{if($0~"AEM_PASSWORD") print}' | awk -F '=' '{print $2}')
readonly IP65=$(cat $BASE_PATH/$CONFIG_INI | awk '{if($0~"AEM_IP") print}' | awk -F '=' '{print $2}')
readonly PORT65=$(cat $BASE_PATH/$CONFIG_INI | awk '{if($0~"AEM_PORT") print}' | awk -F '=' '{print $2}')

# CHECK CONFIG
if [[ $XML_URL == "" ]]; then
  echo 'Error: [config.ini] XML_URL is not find.' >&2
  exit 1
fi
if [[ $USER65 == "" ]]; then
  echo 'Error: [config.ini] USER65 is not find.' >&2
  exit 1
fi
if [[ $IP65 == "" ]]; then
  echo 'Error: [config.ini] IP65 is not find.' >&2
  exit 1
fi
if [[ $PORT65 == "" ]]; then
  echo 'Error: [config.ini] PORT65 is not find.' >&2
  exit 1
fi

# CHECK LOCK EXIST
if [[ -f $BASE_PATH/$CONVERT_LOCK ]]; then
  echo "[*]$BASE_PATH/$CONVERT_LOCK:  file is already exists"
  exit 1
else
  touch $BASE_PATH/$CONVERT_LOCK
fi

#######################################
############### READY #################
#######################################
# GET XML FILE
curl -s -u $USER63:$PASSWORD63 $XML_URL >$BASE_PATH/$TEMP_FILE_ALL

# INIT LOG FILE
# DOWNLOAD LOG
if [ ! -d "$BASE_PATH/$AEM_LOG_FOLDER/download_s3_to_65/" ]; then
  mkdir -p "$BASE_PATH/$AEM_LOG_FOLDER/download_s3_to_65/"
fi
if [ ! -f "$BASE_PATH/$AEM_LOG_FOLDER/download_s3_to_65/success.log" ]; then
  touch "$BASE_PATH/$AEM_LOG_FOLDER/download_s3_to_65/success.log"
fi
if [ ! -f "$BASE_PATH/$AEM_LOG_FOLDER/download_s3_to_65/error.log" ]; then
  touch "$BASE_PATH/$AEM_LOG_FOLDER/download_s3_to_65/error.log"
fi
# UPLOAD LOG
if [ ! -d "$BASE_PATH/$AEM_LOG_FOLDER/upload_65/" ]; then
  mkdir -p "$BASE_PATH/$AEM_LOG_FOLDER/upload_65/"
fi
if [ ! -f "$BASE_PATH/$AEM_LOG_FOLDER/upload_65/success.log" ]; then
  touch "$BASE_PATH/$AEM_LOG_FOLDER/upload_65/success.log"
fi
if [ ! -f "$BASE_PATH/$AEM_LOG_FOLDER/upload_65/error.log" ]; then
  touch "$BASE_PATH/$AEM_LOG_FOLDER/upload_65/error.log"
fi
# INSTALL LOG
if [ ! -d "$BASE_PATH/$AEM_LOG_FOLDER/install_65/" ]; then
  mkdir -p "$BASE_PATH/$AEM_LOG_FOLDER/install_65/"
fi
if [ ! -f "$BASE_PATH/$AEM_LOG_FOLDER/install_65/success.log" ]; then
  touch "$BASE_PATH/$AEM_LOG_FOLDER/install_65/success.log"
fi
if [ ! -f "$BASE_PATH/$AEM_LOG_FOLDER/install_65/error.log" ]; then
  touch "$BASE_PATH/$AEM_LOG_FOLDER/install_65/error.log"
fi

# DOWNLOAD FILE FOLDER
if [ ! -d "$BASE_PATH/$AEM_DOWNLOAD_FOLDER/" ]; then
  mkdir -p "$BASE_PATH/$AEM_DOWNLOAD_FOLDER/"
fi

#######################################
###############  START  ###############
############ LOOP GET ITEM ############
#######################################
for ((i = 1; 1; i++)); do
  # GET ITEM BY XMLLINT
  xmllint --xpath "//channel/item[$i]" $BASE_PATH/$TEMP_FILE_ALL >$BASE_PATH/$TEMP_FILE_ITEM

  ITEM_RESULT=$(cat $BASE_PATH/$TEMP_FILE_ITEM)
  if [[ $ITEM_RESULT == "" ]]; then
    echo -e "\n[*]ITEM READ END, READY TO BUILD ...\n"
    break
  fi
  # ZIP META INFO
  ITEM_TITLE=$(xmllint --xpath "//item/title/text()" $BASE_PATH/$TEMP_FILE_ITEM)
  ITEM_TOTAL=$(xmllint --xpath "//item/p/text()" $BASE_PATH/$TEMP_FILE_ITEM)
  ZIP_NAME=$ITEM_TITLE-$ITEM_TOTAL-$PACKAGE_VERSION.zip
  # Check Aws S3 EXIST
  s3GetResult=$(aws s3 ls $AWS_S3_PATH/$ZIP_NAME)
  s3GetResultFormat=$(echo $s3GetResult | sed 's/^s*//' | sed 's/s*$//')
  if [[ $s3GetResultFormat != "" ]]; then
    if [[ $(cat "$BASE_PATH/$AEM_LOG_FOLDER/download_s3_to_65/success.log" | grep "$ZIP_NAME") != "" ]]; then
      echo "[*]$ZIP_NAME: Has Already Download From S3 !"
      continue
    fi

    # DOWNLOAD FROM S3
    aws s3 cp "$AWS_S3_PATH/$ZIP_NAME" "$BASE_PATH/$AEM_DOWNLOAD_FOLDER/"
    echo $ZIP_NAME >>"$BASE_PATH/$AEM_LOG_FOLDER/download_s3_to_65/success.log"
    echo "[*]S3 DOWNLOAD SUCCESS: [$ZIP_NAME]"

    # UPLOAD 6.5 AEM
    packagePass=$BASE_PATH/$AEM_DOWNLOAD_FOLDER/$ZIP_NAME
    UPLOAD_RES=$(curl -sSi -u $USER65:$PASSWORD65 -F cmd=upload -F force=true -F package=@${packagePass} http://$IP65:$PORT65/crx/packmgr/service/.json | awk -F 'success' '/msg/{print $0}')
    IS_SUCCESS=$(echo $UPLOAD_RES | sed 's/,/\n/g' | grep "success" | sed 's/:/\n/g' | sed '1d' | sed 's/}//g')
    if [[ $IS_SUCCESS == "true" ]]; then
      if [[ $(cat "$BASE_PATH/$AEM_LOG_FOLDER/upload_65/success.log" | grep "$ZIP_NAME") == "" ]]; then
        echo $ZIP_NAME >>"$BASE_PATH/$AEM_LOG_FOLDER/upload_65/success.log"
        echo "[*]UPLOAD SUCCESS: [$packagePass]"
      fi
    else
      if [[ $(cat "$BASE_PATH/$AEM_LOG_FOLDER/upload_65/error.log" | grep "$ZIP_NAME") == "" ]]; then
        echo $ZIP_NAME >>"$BASE_PATH/$AEM_LOG_FOLDER/upload_65/error.log"
        echo "[*]UPLOAD ERROR: [$packagePass]"
      fi
      continue
    fi

    # INSTALL 6.5 AEM
    INSTALL_RES=$(curl -sSi -u $USER65:$PASSWORD65 -F cmd=install http://$IP65:$PORT65/crx/packmgr/service/.json/etc/packages/$GROUP_NAME/$ZIP_NAME | awk '{if($0~"success") print}')
    IS_INSTALL_SUCCESS=$(echo $INSTALL_RES | sed 's/,/\n/g' | grep "success" | sed 's/:/\n/g' | sed '1d' | sed 's/}//g')
    if [[ $IS_INSTALL_SUCCESS == "true" ]]; then
      if [[ $(cat "$BASE_PATH/$AEM_LOG_FOLDER/install_65/success.log" | grep "$ZIP_NAME") == "" ]]; then
        echo $ZIP_NAME >>"$BASE_PATH/$AEM_LOG_FOLDER/install_65/success.log"
        echo "[*]INSTALL SUCCESS: [$packagePass]"
      fi
    else
      if [[ $(cat "$BASE_PATH/$AEM_LOG_FOLDER/install_65/error.log" | grep "$ZIP_NAME") == "" ]]; then
        echo $ZIP_NAME >>"$BASE_PATH/$AEM_LOG_FOLDER/install_65/error.log"
        echo "[*]INSTALL ERROR: [$packagePass]"
      fi
    fi

  fi

done

# DELETE TEMP FILE
rm -rf "$BASE_PATH/$TEMP_FILE_ALL"
rm -rf "$BASE_PATH/$TEMP_FILE_ITEM"
# REMOVE THE LOCK
rm -rf $BASE_PATH/$CONVERT_LOCK

echo "[*]!!! Execution complete !!!"
