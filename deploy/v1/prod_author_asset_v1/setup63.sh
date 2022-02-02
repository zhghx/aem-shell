#!/bin/bash 

rm -rf ./convert63
mkdir ./convert63
aws s3 cp s3://vx-tokyo/tmp/tei_work/prod_author_asset_v1/convert63/config.ini ./convert63/
aws s3 cp s3://vx-tokyo/tmp/tei_work/prod_author_asset_v1/convert63/convert_63.sh ./convert63/
aws s3 cp s3://vx-tokyo/tmp/tei_work/prod_author_asset_v1/convert63/start.sh ./convert63/
aws s3 cp s3://vx-tokyo/tmp/tei_work/prod_author_asset_v1/convert63/test.sh ./convert63/

echo "[*]Download temp_all.xml"

aws s3 cp s3://vx-tokyo/tmp/tei_work/prod_author_asset_v1/convert63/temp_all.xml ./convert63/
