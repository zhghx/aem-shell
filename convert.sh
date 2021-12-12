#!/bin/sh

XML_URL=http://127.0.0.1/res.xml
TEMP_FILE_ALL=temp_all.xml
TEMP_FILE_ITEM=item.xml

# GET XML FILE
curl -s $XML_URL > $TEMP_FILE_ALL

#INDEX=1
#while :; do
#  xmllint --xpath "//channel/item[$INDEX]" $TEMP_FILE_ALL
#  case $aNum in
#  1 | 2 | 3 | 4 | 5)
#    echo "Your number is $aNum!"
#    ;;
#  *)
#    echo "You do not select a number between 1 to 5, game is over!"
#    break
#    ;;
#  esac
#done
#xmllint --xpath '//channel/item[12]' $TEMP_FILE_ALL

function itemHandle() {
  TEMP_FILTER_LIST_STR=$3
  TEMP_FILTER_LIST_STR=(`sort  ${TEMP_FILTER_LIST_STR}`)
  echo $1 "-" $2 "-" ${#TEMP_FILTER_LIST_STR[*]}
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

  ITEM_TITLE=`xmllint --xpath "//item/title/text()" $TEMP_FILE_ITEM`
  ITEM_TOTAL=`xmllint --xpath "//item/p/text()" $TEMP_FILE_ITEM`
  ITEM_FILTER_LIST=()

  for((j = 1; 1; j++));
  do
    FILTER_ROOT=`xmllint --xpath "//item/description/filter[$j]/@root" $TEMP_FILE_ITEM`
    if [[ $FILTER_ROOT == "" ]]
    then
      echo "[*]FILTER READ END ..."
      break
    fi
    ITEM_FILTER_LIST=("${ITEM_FILTER_LIST[@]}" $FILTER_ROOT)
#    echo ${#ITEM_FILTER_LIST[@]}
  done

#  echo ${ITEM_FILTER_LIST[*]}

#  echo ${ITEM_FILTER_LIST[*]}
  itemHandle $ITEM_TITLE $ITEM_TOTAL `echo ${ITEM_FILTER_LIST[*]}`

#  ITEM_RESULT=`xmllint --xpath "//channel/item[$i]" $TEMP_FILE_ALL`
#  echo "\n"
#  echo $ITEM_RESULT
#  ITEM_RESULT=`xmllint --xpath "//channel/item[$i]" $TEMP_FILE_ALL`

  #echo $(expr $i \* 3 + 1);
done
