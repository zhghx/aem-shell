#!/bin/sh

XML_URL=http://127.0.0.1/res.xml
TEMP_FILE_ALL=temp_all.xml
TEMP_FILE_ITEM=item.xml

# GET XML FILE
curl -s $XML_URL > $TEMP_FILE_ALL

function itemHandle(){
  TEMP_ITEM_FILTER_LIST=(`echo $3 | tr '|' ' '`)
  for x in "${!TEMP_ITEM_FILTER_LIST[@]}"; do
      echo "$x:${TEMP_ITEM_FILTER_LIST[i]}"
  done
  echo "PackageName:[$1]; PackageSize:[$2]; FilterCount:[${#TEMP_ITEM_FILTER_LIST[@]}]"
}

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
  ITEM_FILTER_LIST_STR=""
  ITEM_FILTER_LIST_SEPARATION="|"

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
    if [[ $ITEM_FILTER_LIST_STR != "" ]]
    then
      ITEM_FILTER_LIST_STR="$ITEM_FILTER_LIST_STR$ITEM_FILTER_LIST_SEPARATION"
    fi
    ITEM_FILTER_LIST_STR="$ITEM_FILTER_LIST_STR$FILTER_ROOT"
  done
  itemHandle $ITEM_TITLE $ITEM_TOTAL $ITEM_FILTER_LIST_STR
done
