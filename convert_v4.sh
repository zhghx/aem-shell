#!/bin/bash

# xml data sources
readonly XML_URL=http://54.92.43.67:7771/res.xml

# aem server info for (upload, build, download)
readonly USER63="admin"
readonly PASSWORD63="adminadmin"
readonly IP63="54.92.43.67"
readonly PORT63=7769
# aws s3
readonly AWS_S3_PATH="s3://oss-zhghx"

# SYSTEM CONFIG
readonly TEMP_FILE_ALL=temp_all.xml
readonly TEMP_FILE_ITEM=temp_item.xml
readonly ALL_PACKAGE_IFNO_XML=all_package.xml
readonly FILTER_FILE=filter.xml
readonly PROPERTIES_FILE=properties.xml
readonly AEM_ZIP_FOLDER=pre_build_zip
readonly AEM_LOG_FOLDER=logs
readonly AEM_DOWNLOAD_FOLDER=download_build_done_zip
readonly GROUP_NAME=shell_upload_group
readonly PACKAGE_VERSION=$(date +%Y%m%d)

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
  # CHECK UPLOAD LOG FOLDER AND FILE
  if [ ! -d "$BASE_PATH/$AEM_LOG_FOLDER/upload/" ]; then
    mkdir -p "$BASE_PATH/$AEM_LOG_FOLDER/upload/"
  fi
  if [ ! -f "$BASE_PATH/$AEM_LOG_FOLDER/upload/success.log" ]; then
    touch "$BASE_PATH/$AEM_LOG_FOLDER/upload/success.log"
  fi
  if [ ! -f "$BASE_PATH/$AEM_LOG_FOLDER/upload/error.log" ]; then
    touch "$BASE_PATH/$AEM_LOG_FOLDER/upload/error.log"
  fi
  ZIP_FILE_NAME=$(echo $packagePass | awk -F '/' '{print $NF}')
  # CHECK ALREADY UPLOADED
  if [[ $(cat "$BASE_PATH/$AEM_LOG_FOLDER/upload/success.log" | grep "$ZIP_FILE_NAME") != "" ||
  $(cat "$BASE_PATH/$AEM_LOG_FOLDER/upload/error.log" | grep "$ZIP_FILE_NAME") != "" ]]; then
    echo "[*]$ZIP_FILE_NAME: Has Already Been Uploaded !"
    return
  fi
  # UPLOADING
  UPLOAD_RES=$(curl -sSi -u ${user}:${password} -F cmd=upload -F force=true -F package=@${packagePass} http://${ip}:$PORT63/crx/packmgr/service/.json | awk -F 'success' '/msg/{print $0}')
  IS_SUCCESS=$(echo $UPLOAD_RES | sed 's/,/\n/g' | grep "success" | sed 's/:/\n/g' | sed '1d' | sed 's/}//g')
  if [[ $IS_SUCCESS == "true" ]]; then
    echo $ZIP_FILE_NAME >>"$BASE_PATH/$AEM_LOG_FOLDER/upload/success.log"
    echo "[*]UPLOAD SUCCESS: [$packagePass]"
  else
    echo $ZIP_FILE_NAME >>"$BASE_PATH/$AEM_LOG_FOLDER/upload/error.log"
    echo "[*]UPLOAD ERROR: [$packagePass]"
  fi
}

# RE-UPLOAD TIMES
readonly MAX_RE_UPLOAD_TIMES=3
# IF EXIST ERROR UPLOAD LOG, Recursive execution
function reUploadPackage() {
  # Check Param
  if [ $# != 4 ]; then
    echo "[ERR]reUploadPackage param error:" $*
    exit 1
  fi
  user=$1
  password=$2
  ip=$3
  # MAX LOOP TIMES HANDLE
  INIT_RE_UPLOAD_TIMES=$4
  ((INIT_RE_UPLOAD_TIMES++))
  echo -e "\n[*]reUploadPackage Start [$INIT_RE_UPLOAD_TIMES] times ... \n"
  echo -e "[*]reUploadPackage Check re-uploaded ... \n"
  # CHECK UPLOAD ERROR LOG (No error log exists)
  if [ ! -f "$BASE_PATH/$AEM_LOG_FOLDER/upload/error.log" ]; then
    echo "[OK]reUploadPackage No Files That Need To Be Re-Uploaded !"
    return
  fi
  if [ ! -s "$BASE_PATH/$AEM_LOG_FOLDER/upload/error.log" ]; then
    echo "[OK]reUploadPackage No Files That Need To Be Re-Uploaded !"
    return
  fi
  # EXIST ERROR UPLOAD LOG
  echo -e "[*]reUploadPackage Files Exist That Need To Be Re-Uploaded !\n"
  for line in $(cat $BASE_PATH/$AEM_LOG_FOLDER/upload/error.log); do
    packagePass="$BASE_PATH/$AEM_ZIP_FOLDER/$line"
    UPLOAD_RES=$(curl -sSi -u ${user}:${password} -F cmd=upload -F force=true -F package=@${packagePass} http://${ip}:$PORT63/crx/packmgr/service/.json | awk -F 'success' '/msg/{print $0}')
    IS_SUCCESS=$(echo $UPLOAD_RES | sed 's/,/\n/g' | grep "success" | sed 's/:/\n/g' | sed '1d' | sed 's/}//g')
    ZIP_FILE_NAME=$(echo $packagePass | awk -F '/' '{print $NF}')
    if [[ $IS_SUCCESS == "true" ]]; then
      # DELETE ERROR LOG
      sed -i "/$line/d" "$BASE_PATH/$AEM_LOG_FOLDER/upload/error.log"
      if [[ $(cat "$BASE_PATH/$AEM_LOG_FOLDER/upload/success.log" | grep "$ZIP_FILE_NAME") != "" ]]; then
        continue
      fi
      echo $ZIP_FILE_NAME >>"$BASE_PATH/$AEM_LOG_FOLDER/upload/success.log"
      echo "[*]RE UPLOAD SUCCESS: [$packagePass]"
    else
      if [[ $(cat "$BASE_PATH/$AEM_LOG_FOLDER/upload/error.log" | grep "$ZIP_FILE_NAME") != "" ]]; then
        continue
      fi
      echo $ZIP_FILE_NAME >>"$BASE_PATH/$AEM_LOG_FOLDER/upload/error.log"
      echo "[*]RE UPLOAD ERROR: [$packagePass]"
    fi
  done
  if [[ -s "$BASE_PATH/$AEM_LOG_FOLDER/upload/error.log" ]]; then
    if [[ $INIT_RE_UPLOAD_TIMES -ge $MAX_RE_UPLOAD_TIMES ]]; then
      echo -e "\n[*]Re-Upload Times >= Max Re-Upload Times !\n"
      return
    fi
    reUploadPackage $user $password $ip $INIT_RE_UPLOAD_TIMES
  fi
}

# BUILD PACKAGE TO AEM
function buildPackage() {
  # CHECK PARAM
  if [ $# != 3 ]; then
    echo "[ERR]buildPackage Param Error:" $*
    exit 1
  fi
  user=$1
  password=$2
  ip=$3
  # CHECK upload/success.log
  if [ ! -f "$BASE_PATH/$AEM_LOG_FOLDER/upload/success.log" ]; then
    echo "[ERR]All uploads failed !"
    exit 1
  fi
  # CHECK BUILD LOG FOLDER AND FILE
  if [ ! -d "$BASE_PATH/$AEM_LOG_FOLDER/build/" ]; then
    mkdir -p "$BASE_PATH/$AEM_LOG_FOLDER/build/"
  fi
  if [ ! -f "$BASE_PATH/$AEM_LOG_FOLDER/build/success.log" ]; then
    touch "$BASE_PATH/$AEM_LOG_FOLDER/build/success.log"
  fi
  if [ ! -f "$BASE_PATH/$AEM_LOG_FOLDER/build/error.log" ]; then
    touch "$BASE_PATH/$AEM_LOG_FOLDER/build/error.log"
  fi
  # LOOP upload/success.log
  for line in $(cat $BASE_PATH/$AEM_LOG_FOLDER/upload/success.log); do
    zipName="$(echo $line | awk -F '.' '{print $1}')-$PACKAGE_VERSION.$(echo $line | awk -F '.' '{print $2}')"
    packagePass="/etc/packages/$GROUP_NAME/$zipName"
    # CHECK ALREADY BUILD
    if [[ $(cat "$BASE_PATH/$AEM_LOG_FOLDER/build/success.log" | grep "$packagePass") != "" ||
    $(cat "$BASE_PATH/$AEM_LOG_FOLDER/build/error.log" | grep "$packagePass") != "" ]]; then
      echo "[*]$packagePass: Has Already Been Build !"
      continue
    fi
    BUILD_RES=$(curl -sSi -u ${user}:${password} -X POST http://${ip}:$PORT63/crx/packmgr/service/.json${packagePass}?cmd=build | awk -F 'success' '/msg/{print $0}')
    IS_SUCCESS=$(echo $BUILD_RES | sed 's/,/\n/g' | grep "success" | sed 's/:/\n/g' | sed '1d' | sed 's/}//g')
    if [[ $IS_SUCCESS == "true" ]]; then
      echo $packagePass >>"$BASE_PATH/$AEM_LOG_FOLDER/build/success.log"
      echo "[*]BUILD SUCCESS: [$packagePass]"
    else
      echo $packagePass >>"$BASE_PATH/$AEM_LOG_FOLDER/build/error.log"
      echo "[*]BUILD ERROR: [$packagePass]"
    fi
  done
}

# RE-UPLOAD TIMES
readonly MAX_RE_BUILD_TIMES=3
# IF EXIST ERROR BUILD LOG, Recursive execution
function reBuildPackage() {
  # Check Param
  if [ $# != 4 ]; then
    echo "[ERR]reBuildPackage param error:" $*
    exit 1
  fi
  user=$1
  password=$2
  ip=$3
  # MAX LOOP TIMES HANDLE
  INIT_RE_BUILD_TIMES=$4
  ((INIT_RE_BUILD_TIMES++))
  echo -e "\n[*]reBuildPackage Start [$INIT_RE_BUILD_TIMES] times ... \n"
  echo -e "[*]reBuildPackage Check Re-Build ... \n"
  # CHECK BUILD ERROR LOG (No error log exists)
  if [ ! -f "$BASE_PATH/$AEM_LOG_FOLDER/build/error.log" ]; then
    echo -e "[OK]reBuildPackage No Files That Need To Be Re-Build !\n"
    return
  fi
  if [ ! -s "$BASE_PATH/$AEM_LOG_FOLDER/build/error.log" ]; then
    echo -e "[OK]reBuildPackage No Files That Need To Be Re-Build !\n"
    return
  fi
  # EXIST ERROR BUILD LOG
  echo -e "[*]reBuildPackage Files Exist That Need To Be Re-Build !\n"
  for line in $(cat $BASE_PATH/$AEM_LOG_FOLDER/build/error.log); do
    BUILD_RES=$(curl -sSi -u ${user}:${password} -X POST http://${ip}:$PORT63/crx/packmgr/service/.json${line}?cmd=build | awk -F 'success' '/msg/{print $0}')
    IS_SUCCESS=$(echo $BUILD_RES | sed 's/,/\n/g' | grep "success" | sed 's/:/\n/g' | sed '1d' | sed 's/}//g')
    if [[ $IS_SUCCESS == "true" ]]; then
      # DELETE ERROR LOG
      FORMAT_LINE=$(echo "$line" | sed 's#/#\\\/#g')
      sed -i "/$FORMAT_LINE/d" "$BASE_PATH/$AEM_LOG_FOLDER/build/error.log"
      if [[ $(cat "$BASE_PATH/$AEM_LOG_FOLDER/build/success.log" | grep "$line") != "" ]]; then
        continue
      fi
      echo $line >>"$BASE_PATH/$AEM_LOG_FOLDER/build/success.log"
      echo "[*]RE BUILD SUCCESS: [$line]"
    else
      if [[ $(cat "$BASE_PATH/$AEM_LOG_FOLDER/build/error.log" | grep "$line") != "" ]]; then
        continue
      fi
      echo $line >>"$BASE_PATH/$AEM_LOG_FOLDER/build/error.log"
      echo "[*]RE BUILD ERROR: [$line]"
    fi
  done
  if [[ -s "$BASE_PATH/$AEM_LOG_FOLDER/build/error.log" ]]; then
    if [[ $INIT_RE_BUILD_TIMES -ge $MAX_RE_BUILD_TIMES ]]; then
      echo -e "\n[*]Re-Build Times >= Max Re-Build Times !\n"
      return
    fi
    reBuildPackage $user $password $ip $INIT_RE_BUILD_TIMES
  fi
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
  # CHECK build/success.log
  if [ ! -f "$BASE_PATH/$AEM_LOG_FOLDER/build/success.log" ]; then
    echo "[ERR]All builds failed !"
    exit 1
  fi
  # CHECK DOWNLOAD LOG FOLDER AND FILE
  if [ ! -d "$BASE_PATH/$AEM_DOWNLOAD_FOLDER/" ]; then
    mkdir -p "$BASE_PATH/$AEM_DOWNLOAD_FOLDER/"
  fi
  # CHECK BUILD LOG FOLDER AND FILE
  if [ ! -d "$BASE_PATH/$AEM_LOG_FOLDER/download/" ]; then
    mkdir -p "$BASE_PATH/$AEM_LOG_FOLDER/download/"
  fi
  if [ ! -f "$BASE_PATH/$AEM_LOG_FOLDER/download/success.log" ]; then
    touch "$BASE_PATH/$AEM_LOG_FOLDER/download/success.log"
  fi
  if [ ! -f "$BASE_PATH/$AEM_LOG_FOLDER/download/error.log" ]; then
    touch "$BASE_PATH/$AEM_LOG_FOLDER/download/error.log"
  fi
  echo -e "\n[*]READY TO DOWNLOAD ... \n"
  # LOOP upload/success.log
  for line in $(cat $BASE_PATH/$AEM_LOG_FOLDER/build/success.log); do
    ZIP_FILE_NAME=$(echo "$line" | awk -F '/' '{print $NF}')
    # CHECK ALREADY DOWNLOAD
    if [[ $(cat "$BASE_PATH/$AEM_LOG_FOLDER/download/success.log" | grep "http://${ip}:$PORT63$line") != "" ||
    $(cat "$BASE_PATH/$AEM_LOG_FOLDER/download/error.log" | grep "http://${ip}:$PORT63$line") != "" ]]; then
      echo "[*]$line: Has Already Download !"
      continue
    fi
    echo "[*]>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
    echo "[*]Start Download: [http://${ip}:$PORT63$line] "
    curl -u ${user}:${password} http://${ip}:$PORT63$line -o "$BASE_PATH/$AEM_DOWNLOAD_FOLDER/$ZIP_FILE_NAME"
    echo -e "[*]Download Complete !\n"
  done
  # GET ALL PACKAGE INFO
  echo ""
  echo "[*]>>>>>>>>>>>>>> GET ALL PACKAGE INFO XML: [$ALL_PACKAGE_IFNO_XML] >>>>>>>>>>>>>>>>>"
  curl -u ${user}:${password} http://${ip}:$PORT63/crx/packmgr/service.jsp?cmd=ls >$BASE_PATH/$ALL_PACKAGE_IFNO_XML
  echo "[*]<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
  echo ""
  # CHECK DOWNLOAD SIZE
  for file in $BASE_PATH/$AEM_DOWNLOAD_FOLDER/*; do
    actualSize=$(ls -l $file | awk -F ' ' '{print $5}')
    downloadZipName=$(echo $file | awk -F '/' '{print $NF}')
    remoteSize=$(xmllint --xpath "//package[downloadName='$downloadZipName']/size/text()" $BASE_PATH/$ALL_PACKAGE_IFNO_XML)
    packagePass="http://${ip}:$PORT63/etc/packages/$GROUP_NAME/$downloadZipName"
    if [[ $actualSize == $remoteSize ]]; then
      if [[ $(cat "$BASE_PATH/$AEM_LOG_FOLDER/download/success.log" | grep "$packagePass") != "" ]]; then
        continue
      fi
      echo $packagePass >>"$BASE_PATH/$AEM_LOG_FOLDER/download/success.log"
      echo "[*]DOWNLOAD SUCCESS: [$packagePass]"
    else
      if [[ $(cat "$BASE_PATH/$AEM_LOG_FOLDER/download/error.log" | grep "$packagePass") != "" ]]; then
        continue
      fi
      echo $packagePass >>"$BASE_PATH/$AEM_LOG_FOLDER/download/error.log"
      echo "[*]DOWNLOAD ERROR: [$packagePass]"
    fi
  done
  echo ""
  echo "[*]******************************************************"
  echo "[*]*************** All downloads complete ***************"
  echo "[*]******************************************************"
}

# RE-UPLOAD TIMES
readonly MAX_RE_DOWNLOAD_TIMES=3
# IF EXIST ERROR DOWNLOAD LOG, Recursive execution
function reDownloadPackage() {
  # Check Param
  if [ $# != 4 ]; then
    echo "[ERR]reDownloadPackage param error:" $*
    exit 1
  fi
  user=$1
  password=$2
  ip=$3
  # MAX LOOP TIMES HANDLE
  INIT_RE_DOWNLOAD_TIMES=$4
  ((INIT_RE_DOWNLOAD_TIMES++))
  echo ""
  echo -e "[*]reDownloadPackage Start [$INIT_RE_DOWNLOAD_TIMES] times ... \n"
  echo -e "[*]reDownloadPackage Check Re-Download ... \n"
  # CHECK DOWNLOAD ERROR LOG (No error log exists)
  if [ ! -f "$BASE_PATH/$AEM_LOG_FOLDER/download/error.log" ]; then
    echo -e "[OK]reDownloadPackage No Files That Need To Be Re-Download !\n"
    return
  fi
  if [ ! -s "$BASE_PATH/$AEM_LOG_FOLDER/download/error.log" ]; then
    echo -e "[OK]reDownloadPackage No Files That Need To Be Re-Download !\n"
    return
  fi
  # EXIST ERROR DOWNLOAD LOG
  echo -e "[*]reDownloadPackage Files Exist That Need To Be Re-Download !\n"
  for line in $(cat $BASE_PATH/$AEM_LOG_FOLDER/download/error.log); do
    downloadZipName=$(echo $line | awk -F '/' '{print $NF}')
    echo "[*]>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
    echo "[*]Start Re-Download: [$line]"
    curl -u ${user}:${password} $line -o "$BASE_PATH/$AEM_DOWNLOAD_FOLDER/$downloadZipName"
    echo -e "[*]Download Re-Complete !\n"
    actualSize=$(ls -l "$BASE_PATH/$AEM_DOWNLOAD_FOLDER/$downloadZipName" | awk -F ' ' '{print $5}')
    remoteSize=$(xmllint --xpath "//package[downloadName='$downloadZipName']/size/text()" $BASE_PATH/$ALL_PACKAGE_IFNO_XML)
    if [[ $actualSize == $remoteSize ]]; then
      # DELETE ERROR LOG
      FORMAT_LINE=$(echo "$line" | sed 's#/#\\\/#g')
      sed -i "/$FORMAT_LINE/d" "$BASE_PATH/$AEM_LOG_FOLDER/download/error.log"
      if [[ $(cat "$BASE_PATH/$AEM_LOG_FOLDER/download/success.log" | grep "$line") != "" ]]; then
        continue
      fi
      echo $line >>"$BASE_PATH/$AEM_LOG_FOLDER/download/success.log"
      echo -e "[*]RE-DOWNLOAD SUCCESS: [$line]\n"
    else
      if [[ $(cat "$BASE_PATH/$AEM_LOG_FOLDER/download/error.log" | grep "$line") != "" ]]; then
        continue
      fi
      echo $line >>"$BASE_PATH/$AEM_LOG_FOLDER/download/error.log"
      echo -e "[*]RE-DOWNLOAD ERROR: [$line]\n"
    fi
  done
  if [[ -s "$BASE_PATH/$AEM_LOG_FOLDER/download/error.log" ]]; then
    if [[ $INIT_RE_DOWNLOAD_TIMES -ge $MAX_RE_DOWNLOAD_TIMES ]]; then
      echo -e "\n[*]Re-Download Times >= Max Re-Download Times !\n"
      return
    fi
    reDownloadPackage $user $password $ip $INIT_RE_DOWNLOAD_TIMES
  fi
}

# UPLOAD AEM ZIP TO AWS S3
function uploadToAwsS3() {
  # CHECK BUILD LOG FOLDER AND FILE
  if [ ! -d "$BASE_PATH/$AEM_LOG_FOLDER/s3_upload/" ]; then
    mkdir -p "$BASE_PATH/$AEM_LOG_FOLDER/s3_upload/"
  fi
  if [ ! -f "$BASE_PATH/$AEM_LOG_FOLDER/s3_upload/success.log" ]; then
    touch "$BASE_PATH/$AEM_LOG_FOLDER/s3_upload/success.log"
  fi
  if [ ! -f "$BASE_PATH/$AEM_LOG_FOLDER/s3_upload/error.log" ]; then
    touch "$BASE_PATH/$AEM_LOG_FOLDER/s3_upload/error.log"
  fi
  for line in $(cat $BASE_PATH/$AEM_LOG_FOLDER/download/success.log); do
    zipName=$(echo $line | awk -F '/' '{print $NF}')
    zipLocalPath=$BASE_PATH/$AEM_DOWNLOAD_FOLDER/$zipName
    s3GetResult=$(aws s3 ls $AWS_S3_PATH/$zipName)
    s3GetResultFormat=$(echo $s3GetResult | sed 's/^s*//' | sed 's/s*$//')
    if [[ $s3GetResultFormat != "" ]]; then
      echo "[*][$zipName]: AWS S3 Has Already Been Uploaded !"
    else
      aws s3 cp "$zipLocalPath" "$AWS_S3_PATH/"
      s3CheckResult=$(aws s3 ls $AWS_S3_PATH/$zipName | awk -F ' ' '{print $3}')
      remoteSize=$(xmllint --xpath "//package[downloadName='$zipName']/size/text()" $BASE_PATH/$ALL_PACKAGE_IFNO_XML)
      if [[ $s3CheckResult == $remoteSize ]]; then
        if [[ $(cat "$BASE_PATH/$AEM_LOG_FOLDER/s3_upload/success.log" | grep "$zipName") != "" ]]; then
          continue
        fi
        echo $zipName >>"$BASE_PATH/$AEM_LOG_FOLDER/s3_upload/success.log"
        echo "[*]S3 UPLOAD SUCCESS: [$zipName]"
      else
        if [[ $(cat "$BASE_PATH/$AEM_LOG_FOLDER/s3_upload/error.log" | grep "$zipName") != "" ]]; then
          continue
        fi
        echo $zipName >>"$BASE_PATH/$AEM_LOG_FOLDER/s3_upload/error.log"
        echo "[*]S3 UPLOAD ERROR: [$zipName]"
      fi
    fi
  done
}

# RE-S3-UPLOAD TIMES
readonly MAX_RE_S3_UPLOAD_TIMES=3
# IF EXIST ERROR RE_S3_UPLOAD LOG, Recursive execution
function reUploadToAwsS3() {
  # MAX LOOP TIMES HANDLE
  INIT_RE_S3_UPLOAD_TIMES=$1
  ((INIT_RE_S3_UPLOAD_TIMES++))
  echo ""
  echo -e "[*]reUploadToAwsS3 Start [$INIT_RE_S3_UPLOAD_TIMES] times ... \n"
  echo -e "[*]reUploadToAwsS3 Check Re-S3-Upload ... \n"
  # CHECK RE-S3-UPLOAD ERROR LOG (No error log exists)
  if [ ! -f "$BASE_PATH/$AEM_LOG_FOLDER/s3_upload/error.log" ]; then
    echo -e "[OK]reUploadToAwsS3 No Files That Need To Be Re-S3-Upload !\n"
    return
  fi
  if [ ! -s "$BASE_PATH/$AEM_LOG_FOLDER/s3_upload/error.log" ]; then
    echo -e "[OK]reUploadToAwsS3 No Files That Need To Be Re-S3-Upload !\n"
    return
  fi
  # EXIST ERROR RE-S3-UPLOAD LOG
  echo -e "[*]reUploadToAwsS3 Files Exist That Need To Be Re-S3-Upload !\n"
  for zipName in $(cat $BASE_PATH/$AEM_LOG_FOLDER/s3_upload/error.log); do
    zipLocalPath=$BASE_PATH/$AEM_DOWNLOAD_FOLDER/$zipName
    aws s3 cp "$zipLocalPath" "$AWS_S3_PATH/"
    s3CheckResult=$(aws s3 ls $AWS_S3_PATH/$zipName | awk -F ' ' '{print $3}')
    remoteSize=$(xmllint --xpath "//package[downloadName='$zipName']/size/text()" $BASE_PATH/$ALL_PACKAGE_IFNO_XML)
    if [[ $s3CheckResult == $remoteSize ]]; then
      # DELETE ERROR LOG
      sed -i "/$zipName/d" "$BASE_PATH/$AEM_LOG_FOLDER/s3_upload/error.log"
      if [[ $(cat "$BASE_PATH/$AEM_LOG_FOLDER/s3_upload/success.log" | grep "$zipName") != "" ]]; then
        continue
      fi
      echo $zipName >>"$BASE_PATH/$AEM_LOG_FOLDER/s3_upload/success.log"
      echo "[*]RE-S3-UPLOAD SUCCESS: [$zipName]"
    fi
  done
  if [[ -s "$BASE_PATH/$AEM_LOG_FOLDER/s3_upload/error.log" ]]; then
    if [[ $INIT_RE_S3_UPLOAD_TIMES -ge $MAX_RE_S3_UPLOAD_TIMES ]]; then
      echo -e "\n[*]Re-S3-Upload Times >= Max Re-S3-Upload Times !\n"
      return
    fi
    reUploadToAwsS3 $INIT_RE_S3_UPLOAD_TIMES
  fi
}

#######################################
############### READY #################
#######################################
# GET XML FILE
curl -s -u $USER63:$PASSWORD63 $XML_URL >$BASE_PATH/$TEMP_FILE_ALL

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

# CHECK AND RE-UPLOAD
echo "[*]======================================================"
echo "[*]============== reUploadPackage ======================="
echo "[*]======================================================"
reUploadPackage $USER63 $PASSWORD63 $IP63 0

# BUILD ZIP TO AEM
echo ""
echo "[*]======================================================"
echo "[*]================ buildPackage ========================"
echo "[*]======================================================"
buildPackage $USER63 $PASSWORD63 $IP63

# CHECK AND RE-BUILD
echo ""
echo "[*]======================================================"
echo "[*]=============== reBuildPackage ======================="
echo "[*]======================================================"
reBuildPackage $USER63 $PASSWORD63 $IP63 0

# DOWNLOAD ZIP TO AEM
echo ""
echo "[*]======================================================"
echo "[*]=============== downloadPackage ======================"
echo "[*]======================================================"
downloadPackage $USER63 $PASSWORD63 $IP63

# CHECK AND RE-DOWNLOAD
echo ""
echo "[*]======================================================"
echo "[*]=============== reDownloadPackage ===================="
echo "[*]======================================================"
reDownloadPackage $USER63 $PASSWORD63 $IP63 0

# UPLOAD TO AWS S3
echo ""
echo "[*]======================================================"
echo "[*]================= uploadToAwsS3 ======================"
echo "[*]======================================================"
uploadToAwsS3

# CHECK AND RE-UPLOAD TO AWS S3
echo ""
echo "[*]======================================================"
echo "[*]================ reUploadToAwsS3 ====================="
echo "[*]======================================================"
reUploadToAwsS3 0

# ZIP　全部で　ダウンロードしたあと -> S3 -> 本番環境
#
# upload
# aws s3 cp ./convert_v4.sh s3://oss-zhghx/
# download
# aws s3 cp s3://oss-zhghx/convert_v4.sh ./
#
# UPLOAD S3
#
# [ec2-user@dvxvz0100201 build]$
# [ec2-user@dvxvz0100201 build]$ aws s3 cp ./success.log s3://vx-tokyo/tmp/yao_work/
# upload: ./success.log to s3://vx-tokyo/tmp/yao_work/success.log
# [ec2-user@dvxvz0100201 build]$
#
# aws s3 cp PACKAGE_NAME s3://path.xxxx/dir/

# DELETE AEM PACKAGE

# DELETE TEMP FILE
rm -rf "$BASE_PATH/$TEMP_FILE_ALL"
rm -rf "$BASE_PATH/$TEMP_FILE_ITEM"

echo "[*]!!! Execution complete !!!"
