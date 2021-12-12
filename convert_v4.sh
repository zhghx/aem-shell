#!/bin/bash

# xml data sources
readonly XML_URL=http://54.92.43.67:7771/res.xml

# aem server info for (upload, build, download)
readonly USER63="admin"
readonly PASSWORD63="adminadmin"
readonly IP63="54.92.43.67"
readonly PORT63=7769

# SYSTEM CONFIG
readonly TEMP_FILE_ALL=temp_all.xml
readonly TEMP_FILE_ITEM=temp_item.xml
readonly FILTER_FILE=filter.xml
readonly PROPERTIES_FILE=properties.xml
readonly AEM_ZIP_FOLDER=pre_build_zip
readonly AEM_LOG_FOLDER=logs
readonly AEM_DOWNLOAD_FOLDER=download_build_done_zip
readonly GROUP_NAME=shell_upload
readonly PACKAGE_VERSION=1.0

# SCRIPT STORAGE DIRECTORY
BASE_PATH=$(
  cd $(dirname $0)
  pwd
)

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

# UPLOAD PACKAGE TO AEM
function uploadPackage() {
  # Check Param
  if [ $# != 4 ]; then
    echo "[ERR]uploadPackage param error:" $*
    exit 1
  fi
  user=$1
  password=$2
  ip=$3
  packagePass=$4
  UPLOAD_RES=$(curl -sSi -u ${user}:${password} -F cmd=upload -F force=true -F package=@${packagePass} http://${ip}:$PORT63/crx/packmgr/service/.json | awk -F 'success' '/msg/{print $0}')
  IS_SUCCESS=$(echo $UPLOAD_RES | sed 's/,/\n/g' | grep "success" | sed 's/:/\n/g' | sed '1d' | sed 's/}//g')
  ZIP_FILE_NAME=$(echo $packagePass | awk -F '/' '{print $NF}')
  # CHECK UPLOAD LOG FOLDER
  if [ ! -d "$BASE_PATH/$AEM_LOG_FOLDER/upload/" ]; then
    mkdir -p "$BASE_PATH/$AEM_LOG_FOLDER/upload/"
  fi
  if [[ $IS_SUCCESS == "true" ]]; then
    echo "[*]UPLOAD SUCCESS: [$packagePass]"
    if [ -f "$BASE_PATH/$AEM_LOG_FOLDER/upload/success.log" ]; then
      touch "$BASE_PATH/$AEM_LOG_FOLDER/upload/success.log"
    fi
    echo $ZIP_FILE_NAME >>"$BASE_PATH/$AEM_LOG_FOLDER/upload/success.log"
  else
    echo "[*]UPLOAD ERROR: [$packagePass]"
    if [ -f "$BASE_PATH/$AEM_LOG_FOLDER/upload/error.log" ]; then
      touch "$BASE_PATH/$AEM_LOG_FOLDER/upload/error.log"
    fi
    echo $ZIP_FILE_NAME >>"$BASE_PATH/$AEM_LOG_FOLDER/upload/error.log"
  fi
}

# BUILD PACKAGE TO AEM
function buildPackage() {
  # Check Param
  if [ $# != 3 ]; then
    echo "[ERR]buildPackage Param Error:" $*
    exit 1
  fi
  user=$1
  password=$2
  ip=$3
  for line in $(cat $BASE_PATH/$AEM_LOG_FOLDER/upload/success.log); do
    zipName="$(echo $line | awk -F '.' '{print $1}')-$PACKAGE_VERSION.$(echo $line | awk -F '.' '{print $2}')"
    packagePass="/etc/packages/$GROUP_NAME/$zipName"
    BUILD_RES=$(curl -sSi -u ${user}:${password} -X POST http://${ip}:$PORT63/crx/packmgr/service/.json${packagePass}?cmd=build | awk -F 'success' '/msg/{print $0}')
    IS_SUCCESS=$(echo $BUILD_RES | sed 's/,/\n/g' | grep "success" | sed 's/:/\n/g' | sed '1d' | sed 's/}//g')
    # CHECK BUILD LOG FOLDER
    if [ ! -d "$BASE_PATH/$AEM_LOG_FOLDER/build/" ]; then
      mkdir -p "$BASE_PATH/$AEM_LOG_FOLDER/build/"
    fi
    if [[ $IS_SUCCESS == "true" ]]; then
      echo "[*]BUILD SUCCESS: [$packagePass]"
      if [ -f "$BASE_PATH/$AEM_LOG_FOLDER/build/success.log" ]; then
        touch "$BASE_PATH/$AEM_LOG_FOLDER/build/success.log"
      fi
      echo $packagePass >>"$BASE_PATH/$AEM_LOG_FOLDER/build/success.log"
    else
      echo "[*]BUILD ERROR: [$packagePass]"
      if [ -f "$BASE_PATH/$AEM_LOG_FOLDER/build/error.log" ]; then
        touch "$BASE_PATH/$AEM_LOG_FOLDER/build/error.log"
      fi
      echo $packagePass >>"$BASE_PATH/$AEM_LOG_FOLDER/build/error.log"
    fi
  done
}

# DOWNLOAD AEM PACKAGE
function downloadPackage() {
  # Check Param
  if [ $# != 3 ]; then
    echo "[ERR]downloadPackage Param Error !" $*
    exit 1
  fi
  user=$1
  password=$2
  ip=$3
  # CHECK DOWNLOAD LOG FOLDER
  if [ ! -d "$BASE_PATH/$AEM_DOWNLOAD_FOLDER/" ]; then
    mkdir -p "$BASE_PATH/$AEM_DOWNLOAD_FOLDER/"
  fi
  echo -e "\n[*]READY TO DOWNLOAD ... \n"
  for line in $(cat $BASE_PATH/$AEM_LOG_FOLDER/build/success.log); do
    ZIP_FILE_NAME=$(echo "$line" | awk -F '/' '{print $NF}')
    echo "[*]>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
    echo "[*]Start Download: [$line] "
    curl -u ${user}:${password} http://${ip}:$PORT63/$line -o "$BASE_PATH/$AEM_DOWNLOAD_FOLDER/$ZIP_FILE_NAME"
    echo -e "[*]Download Success !\n"
  done
  echo "[*]******************************"
  echo "[*]*** All downloads complete ***"
  echo "[*]******************************"
}

#######################################
############### READY #################
#######################################
# GET XML FILE
curl -s $XML_URL >$BASE_PATH/$TEMP_FILE_ALL

# CHECK ZIP FOLDER
if [ -d "$BASE_PATH/$AEM_ZIP_FOLDER" ]; then
  rm -rf $BASE_PATH/$AEM_ZIP_FOLDER
fi

# CHECK LOG FOLDER
if [ -d "$BASE_PATH/$AEM_LOG_FOLDER" ]; then
  rm -rf $BASE_PATH/$AEM_LOG_FOLDER
fi

# CHECK DOWNLOAD FOLDER
if [ -d "$BASE_PATH/$AEM_DOWNLOAD_FOLDER" ]; then
  rm -rf $BASE_PATH/$AEM_DOWNLOAD_FOLDER
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
  ITEM_FILTER_LIST=()

  ###########################################
  #### GET CONTENT BY LOOP ITEM'S FILTER ####
  ###########################################
  for ((j = 1; 1; j++)); do
    FILTER_ROOT=$(xmllint --xpath "//item/description/filter[$j]/@root" $BASE_PATH/$TEMP_FILE_ITEM)
    FILTER_ROOT=$(echo "$FILTER_ROOT" | sed s/[[:space:]]//g)
    if [[ $FILTER_ROOT == "" ]]; then
      echo -e "\n[*]FILTER READ END, READY TO MAKE ..."
      break
    fi
    ITEM_FILTER_LIST=("${ITEM_FILTER_LIST[@]}" $FILTER_ROOT)
  done
  echo "[*]PACKAGE NAME:[$ITEM_TITLE]; PACKAGE SIZE:[$ITEM_TOTAL]; FILTER COUNT:[${#ITEM_FILTER_LIST[@]}]"

  #######################################
  ###### MAKING FILTER XML CONTENT ######
  #######################################
  FILTER_XML_CONTENT=''
  FILTER_XML_HEAD='<?xml version="1.0" encoding="UTF-8"?><workspaceFilter version="1.0">'
  FILTER_XML_FOOT='</workspaceFilter>'
  FILTER_XML_TAG_NAME='filter'
  FILTER_XML_CONTENT=$FILTER_XML_HEAD
  for ((x = 0; x < ${#ITEM_FILTER_LIST[@]}; x++)); do
    echo "[$x]:${ITEM_FILTER_LIST[x]}"
    FILTER_XML_CONTENT="$FILTER_XML_CONTENT<$FILTER_XML_TAG_NAME ${ITEM_FILTER_LIST[x]}/>"
  done
  FILTER_XML_CONTENT="$FILTER_XML_CONTENT$FILTER_XML_FOOT"

  ###########################################
  ###### MAKING PROPERTIES XML CONTENT ######
  ###########################################
  PROPERTIES_XML_CONTENT='<?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE properties SYSTEM "http://java.sun.com/dtd/properties.dtd">
  <properties>
  <comment>FileVault Package Properties</comment>
  <entry key="description"></entry>
  <entry key="packageType">content</entry>
  <entry key="lastWrappedBy">'$USER63'</entry>
  <entry key="packageFormatVersion">6.3</entry>
  <entry key="group">'$GROUP_NAME'</entry>
  <entry key="lastModifiedBy">'$USER63'</entry>
  <entry key="buildCount">0</entry>
  <entry key="version">'$PACKAGE_VERSION'</entry>
  <entry key="dependencies">shell upload package</entry>
  <entry key="createdBy">'$USER63'</entry>
  <entry key="name">'"$ITEM_TITLE-$ITEM_TOTAL"'</entry>
  </properties>'

  #######################################
  ##### CREATE ITEM FOLDER AND FILE #####
  #######################################
  mkdir -p "$BASE_PATH/$AEM_ZIP_FOLDER/$ITEM_TITLE-$ITEM_TOTAL/META-INF/vault/"
  mkdir -p "$BASE_PATH/$AEM_ZIP_FOLDER/$ITEM_TITLE-$ITEM_TOTAL/jcr_root/"
  # CREATE FILTER FILE
  touch "$BASE_PATH/$AEM_ZIP_FOLDER/$ITEM_TITLE-$ITEM_TOTAL/META-INF/vault/$FILTER_FILE"
  echo $FILTER_XML_CONTENT >"$BASE_PATH/$AEM_ZIP_FOLDER/$ITEM_TITLE-$ITEM_TOTAL/META-INF/vault/$FILTER_FILE"
  xmllint --format "$BASE_PATH/$AEM_ZIP_FOLDER/$ITEM_TITLE-$ITEM_TOTAL/META-INF/vault/$FILTER_FILE" \
    --output "$BASE_PATH/$AEM_ZIP_FOLDER/$ITEM_TITLE-$ITEM_TOTAL/META-INF/vault/$FILTER_FILE"
  # CREATE PROPERTIES FILE
  touch "$BASE_PATH/$AEM_ZIP_FOLDER/$ITEM_TITLE-$ITEM_TOTAL/META-INF/vault/$PROPERTIES_FILE"
  echo $PROPERTIES_XML_CONTENT >"$BASE_PATH/$AEM_ZIP_FOLDER/$ITEM_TITLE-$ITEM_TOTAL/META-INF/vault/$PROPERTIES_FILE"
  xmllint --format "$BASE_PATH/$AEM_ZIP_FOLDER/$ITEM_TITLE-$ITEM_TOTAL/META-INF/vault/$PROPERTIES_FILE" \
    --output "$BASE_PATH/$AEM_ZIP_FOLDER/$ITEM_TITLE-$ITEM_TOTAL/META-INF/vault/$PROPERTIES_FILE"

  #######################################
  ############## ZIP DOING ##############
  #######################################
  cd "$BASE_PATH/$AEM_ZIP_FOLDER/$ITEM_TITLE-$ITEM_TOTAL/"
  zip -q -r "./$ITEM_TITLE-$ITEM_TOTAL.zip" *
  mv "./$ITEM_TITLE-$ITEM_TOTAL.zip" ../
  cd -
  rm -rf "$BASE_PATH/$AEM_ZIP_FOLDER/$ITEM_TITLE-$ITEM_TOTAL"

  # UPLOAD ZIP TO AEM
  uploadPackage $USER63 $PASSWORD63 $IP63 "$BASE_PATH/$AEM_ZIP_FOLDER/$ITEM_TITLE-$ITEM_TOTAL.zip"

done

# BUILD ZIP TO AEM
buildPackage $USER63 $PASSWORD63 $IP63
# DOWNLOAD ZIP TO AEM
downloadPackage $USER63 $PASSWORD63 $IP63

# DELETE TEMP FILE
rm -rf "$BASE_PATH/$TEMP_FILE_ALL"
rm -rf "$BASE_PATH/$TEMP_FILE_ITEM"
