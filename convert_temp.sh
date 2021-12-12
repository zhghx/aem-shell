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

#readonly XML_URL=http://127.0.0.1/res.xml
#readonly TEMP_FILE_ALL=temp_all.xml
#readonly TEMP_FILE_ITEM=temp_item.xml
#readonly FILTER_FILE=filter.xml
#readonly PROPERTIES_FILE=properties.xml
#readonly AEM_ZIP_FOLDER=filter_zip
#readonly AEM_LOG_FOLDER=logs
#readonly GROUP_NAME=shell_upload
#readonly PACKAGE_VERSION=1.0

# SCRIPT STORAGE DIRECTORY
#BASE_PATH=$(
#  cd $(dirname $0)
#  pwd
#)

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

curl -u admin:adminadmin http://localhost:4502/etc/packages/shell_upload/MG_isetan_mistore_shinjuku3_3-total=946-1.0.zip -o ./MG_isetan_mistore_shinjuku3_3-total=946-1.0.zip

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



