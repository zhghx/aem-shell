#!/bin/bash

#RES=`curl -sSi -u admin:adminadmin -F cmd=upload -F force=true -F package=@./filter_zip/MG_mitsukoshi_mistore_nihombashi_2-total=611.zip http://localhost:4502/crx/packmgr/service/.json | awk -F 'path' '/path/{print $0}'`
#
#TEST='{"success":true,"msg":"Package uploaded","path":"/etc/packages/temporary/pack_e9621223-1643-48f7-bfdb-36dbda158186.zip"}'
#
##echo $RES
#
#dev_id=$(echo $RES | sed 's/,/\n/g' | grep "success" | sed 's/:/\n/g' | sed '1d' | sed 's/}//g')
#
#echo $dev_id
#
#
##curl -u admin:adminadmin -X POST -Fname=TTTTTTTTTTTTTT http://localhost:4502/etc/packages/temporary/pack_f30c4a76-3e56-4d06-bdf9-b840398cf565.zip/jcr:content/vlt:definition
#
#
##"/etc/packages/temporary/pack_f30c4a76-3e56-4d06-bdf9-b840398cf565.zip"
#
#

#ITEM_TITLE=$(xmllint --xpath "//i22tem/title/text()" ./res.xml)
#echo $ITEM_TITLE

#xmllint --xpath "//it22em/title/text()" ./res.xml >/dev/null 3>&1

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
readonly PACKAGE_VERSION=$(date +%Y%m%d)
# aws s3
readonly AWS_S3_PATH="s3://oss-zhghx"

# SCRIPT STORAGE DIRECTORY
BASE_PATH=$(
  cd $(dirname $0)
  pwd
)

# xml data sources
readonly XML_URL=$(cat $BASE_PATH/$CONFIG_INI | awk '{if($0~"XML_URL") print}' | awk -F '=' '{print $2}')
# aem server info for (upload, build, download)
readonly USER63=$(cat $BASE_PATH/$CONFIG_INI | awk '{if($0~"AEM_USER") print}' | awk -F '=' '{print $2}')
readonly PASSWORD63=$(cat $BASE_PATH/$CONFIG_INI | awk '{if($0~"AEM_PASSWORD") print}' | awk -F '=' '{print $2}')
readonly IP63=$(cat $BASE_PATH/$CONFIG_INI | awk '{if($0~"AEM_IP") print}' | awk -F '=' '{print $2}')
readonly PORT63=$(cat $BASE_PATH/$CONFIG_INI | awk '{if($0~"AEM_PORT") print}' | awk -F '=' '{print $2}')

echo $XML_URL
echo $USER63
echo $PASSWORD63
echo $IP63
echo $PORT63

#for line in `cat $BASE_PATH/$AEM_LOG_FOLDER/upload/success.log`
#do
#  echo "`echo $line | awk -F '.' '{print $1}'`-$PACKAGE_VERSION.`echo $line | awk -F '.' '{print $2}'`"
#done

#/etc/packages/shell_upload/MG_mitsukoshi_mistore_ginza_1-total=975-1.0.zip
#
#curl -sSi -u admin:adminadmin -X POST http://localhost:4502/crx/packmgr/service/.json/etc/packages/shell_upload/MG_mitsukoshi_mistore_ginza_1-total=975-1.0.zip?cmd=build

#curl -sSi -u admin:adminadmin -X POST http://localhost:4502/crx/packmgr/service/.json/etc/packages/shell_upload/MG_mitsukoshi_mistore_ginza_1-total=975-1.0.zip?cmd=build

#echo '{"success":true,"msg":"Package uploaded","path":"/etc/packages/shell_upload/MG_isetan_mistore_shinjuku2_1-total=925-1.0.zip"}' | awk -F 'success' '/msg/{print $0}'

#BUILD_RES=$(curl -sSi -u admin:adminadmin -X POST http://localhost:4502/crx/packmgr/service/.json/etc/packages/shell_upload/MG_mitsukoshi_mistore_ginza_1-total=975-1.0.zip?cmd=build | awk -F 'success' '/path/{print $0}')

#echo BUILD_RES

#curl -u admin:adminadmin http://localhost:4502/etc/packages/shell_upload/MG_isetan_mistore_shinjuku3_3-total=946-1.0.zip -o ./MG_isetan_mistore_shinjuku3_3-total=946-1.0.zip

# CHECK COMMAND
#if [ ! -x "$(command -v curl)" ]; then
#  echo 'Error: curl is not installed.' >&2
#  exit 1
#fi
#if [ ! -x "$(command -v zip)" ]; then
#  echo 'Error: xmllint is not installed.' >&2
#  exit 1
#fi
#if [ ! -x "$(command -v xmllint)" ]; then
#  echo 'Error: xmllint is not installed.' >&2
#  exit 1
#fi

#sed -i '/MG_isetan_mistore_shinjuku3_1-total=935.zip/d' $BASE_PATH/$AEM_LOG_FOLDER/upload/error.log
#if [[ `uname` == 'Darwin' ]]; then
#    gsed -i '/MG_isetan_mistore_shinjuku3_1-total=935.zip/d' $BASE_PATH/$AEM_LOG_FOLDER/upload/error.log
#fi
#if [[ `uname` == 'Linux' ]]; then
#    sed -i '/MG_isetan_mistore_shinjuku3_1-total=935.zip/d' $BASE_PATH/$AEM_LOG_FOLDER/upload/error.log
#fi

#echo "$BASE_PATH"
#sed -i '/MG_isetan_mistore_shinjuku3_1-total=935.zip/d' /Users/zhenghegong/CODE/aem-custom/shell/logs/upload/error.log

#sed -i '/xxx/d' filename

#sed -i '//etc/packages/shell_upload_group/MG_isetan_mistore_shinjuku3_3-total=946-20211214.zip/d' /Users/zhenghegong/CODE/aem-custom/shell/logs/build/error.log

#Comfilename=/etc/packages/shell_upload_group/MG_isetan_mistore_shinjuku3_3-total=946-20211214.zip
#Tempname=$(echo $Comfilename | sed 's#\/#\\\/#g')
#echo $Tempname
#
#
#for line in $(cat $BASE_PATH/$AEM_LOG_FOLDER/build/error.log); do
#  Tempname=$(echo $line | sed 's#/#\\\/#g')
#  echo $Tempname
#done

#curl -u admin:adminadmin -X POST http://54.92.43.67:7769/crx/packmgr/service/.json/etc/packages/shell_upload_group/MG_isetan_mistore_shinjuku1_2-total=954-20211214.zip?cmd=preview
#
#curl -u admin:adminadmin -X POST http://localhost:4502/crx/packmgr/service/console.html/etc/packages/shell_upload_group/MG_isetan_mistore_shinjuku1_2-total=954-20211214.zip?cmd=contents

#curl -u admin:adminadmin http://54.92.43.67:7769/crx/packmgr/service.jsp?cmd=ls > ./package.xml

#xmllint --xpath "//package[downloadName='we.retail.config-4.0.0.zip']/size/text()" ./all_package.xml

#for file in $BASE_PATH/$AEM_DOWNLOAD_FOLDER/*; do
#  ACTUAL_SIZE=$(ls -l $file | awk -F ' ' '{print $5}')
#  DOWNLOAD_ZIP_NAME=$(echo $file | awk -F '/' '{print $NF}')
#  REMOTE_SIZE=$(xmllint --xpath "//package[downloadName='$DOWNLOAD_ZIP_NAME']/size/text()" $BASE_PATH/$ALL_PACKAGE_IFNO_XML)
#  #  echo "ACTUAL_SIZE:"$ACTUAL_SIZE";REMOTE_SIZE:"$REMOTE_SIZE
#  if [[ $ACTUAL_SIZE == $REMOTE_SIZE ]]; then
#    echo "OK"
#  else
#    echo "ERR"
#  fi
#done

#for file in $BASE_PATH/$AEM_DOWNLOAD_FOLDER/*; do
#  echo $file
#  aws s3 cp $file s3://oss-zhghx/
#done

#for file in $BASE_PATH/$AEM_DOWNLOAD_FOLDER/*; do
#  actualSize=$(ls -l $file | awk -F ' ' '{print $5}')
#  echo $actualSize
#done

#wget --http-user=admin --http-password=adminadmin http://54.92.43.67:7769/etc/packages/shell_upload_group/MG_isetan_mistore_kyoto_1-total=983-20211216.zip -P "$BASE_PATH/$AEM_DOWNLOAD_FOLDER/$ZIP_FILE_NAME"

#wget --user=admin --password=adminadmin http://54.92.43.67:7769/etc/packages/shell_upload_group/MG_isetan_mistore_kyoto_1-total=983-20211216.zip -P "$BASE_PATH/$AEM_DOWNLOAD_FOLDER/$ZIP_FILE_NAME"

#echo $(ls -l $BASE_PATH/$AEM_DOWNLOAD_FOLDER/aa.zip | awk -F ' ' '{print $5}')

#if [[ ! -f "$BASE_PATH/$AEM_DOWNLOAD_FOLDER/aa.zip" ]]; then
#  echo "NO"
#fi

#wget --user=admin --password=adminadmin http://54.92.43.67:7769/etc/packages/shell_upload_group/MG_mitsukoshi_mistore_matsuyama_1-total=742-20211216.zip -P /Users/zhenghegong/CODE/aem-custom/shell/download_build_done_zip/
#curl -sSi -u admin:adminadmin -F cmd=upload -F force=true -F package=@/Users/zhenghegong/CODE/aem-custom/shell/download_s3_to_65_zip/MG_isetan_mistore_shinjuku3_2-total=934-20211216.zip http://54.92.43.67:7769/crx/packmgr/service/.json | awk '{if($0~"success") print}'

#UPLOAD_RES=$(curl -sSi -u admin:adminadmin -F cmd=install http://54.92.43.67:7769/crx/packmgr/service/.json/etc/packages/shell_upload_group/MG_isetan_mistore_shinjuku3_2-total=934-20211216.zip | awk '{if($0~"success") print}')
#IS_SUCCESS=$(echo $UPLOAD_RES | sed 's/,/\n/g' | grep "success" | sed 's/:/\n/g' | sed '1d' | sed 's/}//g')
#
#echo $IS_SUCCESS

# CHECK BUILD LOG FOLDER AND FILE
#if [ ! -d "$BASE_PATH/$AEM_LOG_FOLDER/s3_upload/" ]; then
#  mkdir -p "$BASE_PATH/$AEM_LOG_FOLDER/s3_upload/"
#fi
#if [ ! -f "$BASE_PATH/$AEM_LOG_FOLDER/s3_upload/success.log" ]; then
#  touch "$BASE_PATH/$AEM_LOG_FOLDER/s3_upload/success.log"
#fi
#if [ ! -f "$BASE_PATH/$AEM_LOG_FOLDER/s3_upload/error.log" ]; then
#  touch "$BASE_PATH/$AEM_LOG_FOLDER/s3_upload/error.log"
#fi
#for line in $(cat $BASE_PATH/$AEM_LOG_FOLDER/download/success.log); do
#  zipName=$(echo $line | awk -F '/' '{print $NF}')
#  zipLocalPath=$BASE_PATH/$AEM_DOWNLOAD_FOLDER/$zipName
#  s3GetResult=$(aws s3 ls $AWS_S3_PATH/$zipName)
#  s3GetResultFormat=$(echo $s3GetResult | sed 's/^s*//' | sed 's/s*$//')
#  #  echo $s3GetResultFormat
#  if [[ $s3GetResultFormat != "" ]]; then
#    echo "[*][$zipName]: AWS S3 Has Already Been Uploaded !"
#  else
#    aws s3 cp "$zipLocalPath" "$AWS_S3_PATH/"
#    s3CheckResult=$(aws s3 ls $AWS_S3_PATH/$zipName | awk -F ' ' '{print $3}')
#    remoteSize=$(xmllint --xpath "//package[downloadName='$zipName']/size/text()" $BASE_PATH/$ALL_PACKAGE_IFNO_XML)
#    if [[ $s3CheckResult == $remoteSize ]]; then
#      if [[ $(cat "$BASE_PATH/$AEM_LOG_FOLDER/s3_upload/success.log" | grep "$zipName") != "" ]]; then
#        continue
#      fi
#      echo $zipName >>"$BASE_PATH/$AEM_LOG_FOLDER/s3_upload/success.log"
#      echo "[*]S3 UPLOAD SUCCESS: [$zipName]"
#    else
#      if [[ $(cat "$BASE_PATH/$AEM_LOG_FOLDER/s3_upload/error.log" | grep "$zipName") != "" ]]; then
#        continue
#      fi
#      echo $zipName >>"$BASE_PATH/$AEM_LOG_FOLDER/s3_upload/error.log"
#      echo "[*]S3 UPLOAD ERROR: [$zipName]"
#    fi
#  fi
#done

#remoteSize=5765
#AAA=$(aws s3 ls s3://oss-zhghx/MG_isetan_mistore_urawa_1-total=982-20211215.zip | awk -F ' ' '{print $3}')
#echo $AAA
#if [[ $AAA == $remoteSize ]]; then
#  echo 'OK'
#else
#  echo '----'
#fi

#aws s3 ls s3://oss-zhghx/MG_isetan_mistore_urawa_1-total=982-20211215.zip

#zipLocalPath=$BASE_PATH/$AEM_DOWNLOAD_FOLDER/MG_isetan_mistore_urawa_1-total=982-20211215.zip
#aws s3 cp "$zipLocalPath" "$AWS_S3_PATH/"

#echo $(ls -l "$BASE_PATH/$AEM_DOWNLOAD_FOLDER/MG_isetan_common_1-total=987-20211214.zip" | awk -F ' ' '{print $5}')

#echo "cat //response/*[text()='dfs.datanaode.data.dir'/../value]" | xmllint --shell ./all_package.xml

#echo /etc/packages/shell_upload_group/MG_isetan_mistore_shinjuku1_2-total=954-20211214.zip]
#echo $(echo "/etc/packages/shell_upload/MG_isetan_mistore_shinjuku_1-total=951-1.0.zip" | awk -F '/' '{print $NF}')

#curl -sSi -u ${user}:${password} http://${ip}:4502${packagePass} -o ${outputFilename}
#path=$(
#  cd $(dirname $0)
#  pwd
#)
#
#cd $path
#
#cd ..
#
#echo `pwd`
