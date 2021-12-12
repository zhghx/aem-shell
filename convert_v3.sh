#!/bin/sh

readonly XML_URL=http://127.0.0.1/res.xml
readonly TEMP_FILE_ALL=temp_all.xml
readonly TEMP_FILE_ITEM=item.xml
readonly FILTER_FILE=filter.xml
readonly AEM_ZIP_FILTER_FOLDER=filter_zip
readonly GROUP_NAME=temporary

# AEM6.3環境
readonly USER63="admin" # ユーザ名
readonly PASSWORD63="adminadmin" # パスワード
readonly IP63="localhost" # IPアドレス

# AEM6.5環境
#readonly USER65="admin"
#readonly PASSWORD65="admin"
#readonly IP65="54.168.219.196"

#function renamePackage(){
#  # 引数の個数チェック
#  if [ $# != 6 ]; then
#    echo "renamePackage 引数エラー:" $*
#    exit 1
#  fi
#  user=$1
#  password=$2
#  ip=$3
#  newName=$4
#  groupName=$5
#  actualPackageName=$6
#  curl -sSi -u ${user}:${password} -X POST -Fname=${newName} http://${ip}:4502/etc/packages/${groupName}/${actualPackageName}.zip/jcr:content/vlt:definition
#}

function uploadPackage () {
    # 引数の個数チェック
    if [ $# != 5 ]; then
        echo "uploadPackage 引数エラー:" $*
        exit 1
    fi
    user=$1
    password=$2
    ip=$3
    packagePass=$4
    packageName=$5
    UPLOAD_RES=`curl -sSi -u ${user}:${password} -F cmd=upload -F force=true -F package=@${packagePass} http://${ip}:4502/crx/packmgr/service/.json | awk -F 'success' '/path/{print $0}'`
    IS_SUCCESS=$(echo $UPLOAD_RES | sed 's/,/\n/g' | grep "success" | sed 's/:/\n/g' | sed '1d' | sed 's/}//g')
    if [[ $IS_SUCCESS == "true" ]]
    then
      echo "Upload Success..."
      ACTUAL_PACKAGE_NAME=$(echo $UPLOAD_RES | sed 's/,/\n/g' | grep "path" | sed 's/:/\n/g' | sed '1d' | sed 's/}//g')
      echo $UPLOAD_RES
      echo $ACTUAL_PACKAGE_NAME
      renamePackage $USER63 $PASSWORD63 $IP63 $packageName $GROUP_NAME $ACTUAL_PACKAGE_NAME
    fi
}

# GET XML FILE
curl -s $XML_URL > $TEMP_FILE_ALL

# LOOP GET ITEM
for((i = 1; 1; i++));
do
  xmllint --xpath "//channel/item[$i]" $TEMP_FILE_ALL > $TEMP_FILE_ITEM
  ITEM_RESULT=`cat $TEMP_FILE_ITEM`
  if [[ $ITEM_RESULT == "" ]]
  then
    echo "[*]ITEM READ END ..."
    break
  fi

  # ZIP INFO
  ITEM_TITLE=`xmllint --xpath "//item/title/text()" $TEMP_FILE_ITEM`
  ITEM_TOTAL=`xmllint --xpath "//item/p/text()" $TEMP_FILE_ITEM`
  ITEM_FILTER_LIST=()

  # GET FILTER OF ITEM
  for((j = 1; 1; j++));
  do
    FILTER_ROOT=`xmllint --xpath "//item/description/filter[$j]/@root" $TEMP_FILE_ITEM`
    FILTER_ROOT=`echo "$FILTER_ROOT\c" | sed s/[[:space:]]//g`
    if [[ $FILTER_ROOT == "" ]]
    then
      echo "[*]FILTER READ END ..."
      break
    fi
    ITEM_FILTER_LIST=("${ITEM_FILTER_LIST[@]}" $FILTER_ROOT)
  done

  echo "PackageName:[$ITEM_TITLE]; PackageSize:[$ITEM_TOTAL]; FilterCount:[${#ITEM_FILTER_LIST[@]}]"

  # PRODUCING XML
  XML_CONTENT=''
  XML_HEAD='<?xml version="1.0" encoding="UTF-8"?><workspaceFilter version="1.0">'
  XML_FOOT='</workspaceFilter>'
  XML_FILTER_TAG_NAME='filter'
  XML_CONTENT=$XML_HEAD
  for((x = 1; x<${#ITEM_FILTER_LIST[@]}; x++));
  do
    echo "$x:${ITEM_FILTER_LIST[x]}"
    XML_CONTENT="$XML_CONTENT<$XML_FILTER_TAG_NAME ${ITEM_FILTER_LIST[x]}/>"
  done
  XML_CONTENT="$XML_CONTENT$XML_FOOT"

  # CREATE FILTER XML FILE
  echo $XML_CONTENT > $FILTER_FILE
  xmllint --format $FILTER_FILE --output $FILTER_FILE

  # CHECK ZIP FOLDER
  if [ ! -d "./$AEM_ZIP_FILTER_FOLDER" ]; then
    mkdir ./$AEM_ZIP_FILTER_FOLDER
  fi

  # CHECK ZIP FILE
  if [ ! -f "./$AEM_ZIP_FILTER_FOLDER/$ITEM_TITLE-$ITEM_TOTAL.zip" ]; then
    # IF THE DIRECTORY EXISTS, DELETE AND RECREATE IT
    if [ -d "./$AEM_ZIP_FILTER_FOLDER/$ITEM_TITLE-$ITEM_TOTAL" ]; then
      rm -rf "./$AEM_ZIP_FILTER_FOLDER/$ITEM_TITLE-$ITEM_TOTAL"
    fi
    mkdir -p "./$AEM_ZIP_FILTER_FOLDER/$ITEM_TITLE-$ITEM_TOTAL/META-INF/vault/"
    mkdir -p "./$AEM_ZIP_FILTER_FOLDER/$ITEM_TITLE-$ITEM_TOTAL/jcr_root/"
    mv $FILTER_FILE "./$AEM_ZIP_FILTER_FOLDER/$ITEM_TITLE-$ITEM_TOTAL/META-INF/vault/"
    # ZIP DOING
    cd "./$AEM_ZIP_FILTER_FOLDER/$ITEM_TITLE-$ITEM_TOTAL/"
    zip -q -r "./$ITEM_TITLE-$ITEM_TOTAL.zip" *
    mv "./$ITEM_TITLE-$ITEM_TOTAL.zip" ../
    cd -
    rm -rf "./$AEM_ZIP_FILTER_FOLDER/$ITEM_TITLE-$ITEM_TOTAL"
  fi

  # UPLOAD ZIP TO AEM
  uploadPackage $USER63 $PASSWORD63 $IP63 "./$AEM_ZIP_FILTER_FOLDER/$ITEM_TITLE-$ITEM_TOTAL.zip" "$ITEM_TITLE-$ITEM_TOTAL"

#  $ITEM_TITLE $ITEM_TOTAL $ITEM_FILTER_LIST_STR

done
