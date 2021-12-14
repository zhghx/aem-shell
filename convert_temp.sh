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

for file in $BASE_PATH/$AEM_DOWNLOAD_FOLDER/*; do
  ACTUAL_SIZE=$(ls -l $file | awk -F ' ' '{print $5}')
  DOWNLOAD_ZIP_NAME=$(echo $file | awk -F '/' '{print $NF}')
  REMOTE_SIZE=$(xmllint --xpath "//package[downloadName='$DOWNLOAD_ZIP_NAME']/size/text()" $BASE_PATH/$ALL_PACKAGE_IFNO_XML)
  #  echo "ACTUAL_SIZE:"$ACTUAL_SIZE";REMOTE_SIZE:"$REMOTE_SIZE
  if [[ $ACTUAL_SIZE == $REMOTE_SIZE ]]; then
    echo "OK"
  else
    echo "ERR"
  fi
done

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
