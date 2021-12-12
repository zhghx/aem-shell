#!/bin/bash
############################################################
# AEM コンテンツ移行シェル
#
# 目的：
# AEM6.3から6.5へのバージョンアップに伴うコンテンツ移行のために作成。
#
# できること：
#
# 6.3環境へ事前にアップロードされているパッケージに対して
# 下記定数"PATH_LIST"に指定したファイルに記載されている
# パスのパッケージを6.3環境でビルドし、ローカルへダウンロード後
# 6.5環境へアップロードして、インストールする。
#
###########################################################

################################################
# 使い方
################################################
#
# 1. 6.3環境でビルドするパッケージは事前にアップロードしておく。
# 2. 下記定数は適切に書き換える。
# 3. 定数"PATH_LIST"に指定したファイルに、パッケージのパスを記載する。
#    ex) /etc/packages/<グループ名>/<パッケージ名>.zip
#
################################################
# 定数（必要に応じて変更すること）
################################################

# 処理実行日(変更不要)
readonly EXECUTION_DATE=`date +"%Y%m%d"`

# AEM6.3環境
readonly USER63="admin" # ユーザ名
readonly PASSWORD63="adminadmin" # パスワード
readonly IP63="54.168.99.156" # IPアドレス

# AEM6.5環境
readonly USER65="admin"
readonly PASSWORD65="admin"
readonly IP65="54.168.219.196"

# 6.3環境でビルドするパッケージのパスリスト
readonly PATH_LIST="./path_list.txt"

# 一時的なダウンロードディレクトリ
readonly TEMP_DOWNLOAD_DIR="./tmp_${EXECUTION_DATE}/download"

# ログファイル
readonly LOG_FILE="./AemContentMigration_${EXECUTION_DATE}.log"

################################################
# 関数
################################################

# 指定したパッケージをビルドする
#
# $1 user 処理を実行するAEMユーザ。基本的にadmin。
# $2 password $1で指定したuserのパスワード
# $3 ip パッケージをビルドするサーバのIPアドレス
# $4 packagePass ビルド対象のパッケージへのパス。通常"/etc/packages/<グループ名>/<パッケージ名>.zip"
#
function buildPackage () {

    # 引数の個数チェック
    if [ $# != 4 ]; then
        echo "buildPackage 引数エラー:" $*
        exit 1
    fi
    user=$1
    password=$2
    ip=$3
    packagePass=$4

    curl -sSi -u ${user}:${password} -X POST http://${ip}:4502/crx/packmgr/service/.json${packagePass}?cmd=build
}

# パッケージのダウンロード
#
# $1 user 処理を実行するAEMユーザ。基本的にadmin。
# $2 password $1で指定したuserのパスワード
# $3 ip パッケージをダウンロードするサーバのIPアドレス
# $4 packagePass ダウンロード対象のパッケージへのパス。通常"/etc/packages/<グループ名>/<パッケージ名>.zip"
# $5 outputFilename ダウンロードしたパッケージの出力名 通常"./<パッケージ名>.zip"
#
function downloadPackage () {

    # 引数の個数チェック
    if [ $# != 5 ]; then
        echo "downloadPackage 引数エラー:" $*
        exit 1
    fi
    user=$1
    password=$2
    ip=$3
    packagePass=$4
    outputFilename=$5

    curl -sSi -u ${user}:${password} http://${ip}:4502${packagePass} -o ${outputFilename}
}

# パッケージのアップロード
#
# $1 user 処理を実行するAEMユーザ。基本的にadmin。
# $2 password $1で指定したuserのパスワード
# $3 ip パッケージをアップロードするサーバのIPアドレス
# $4 packagePass アップロード対象のパッケージ(ローカルファイル)へのパス。通常"./<パッケージ名>.zip"
#
function uploadPackage () {

    # 引数の個数チェック
    if [ $# != 4 ]; then
        echo "downloadPackage 引数エラー:" $*
        exit 1
    fi
    user=$1
    password=$2
    ip=$3
    packagePass=$4

    curl -sSi -u ${user}:${password} -F cmd=upload -F force=true -F package=@${packagePass} http://${ip}:4502/crx/packmgr/service/.json
}

# アップロード済みパッケージのインストール
#
# $1 user 処理を実行するAEMユーザ。基本的にadmin。
# $2 password $1で指定したuserのパスワード
# $3 ip パッケージをインストールするサーバのIPアドレス
# $4 packagePass インストール対象のパッケージへのパス。通常"/etc/packages/<グループ名>/<パッケージ名>.zip"
#
function installPackage () {

    # 引数の個数チェック
    if [ $# != 4 ]; then
        echo "downloadPackage 引数エラー:" $*
        exit 1
    fi
    user=$1
    password=$2
    ip=$3
    packagePass=$4

    curl -sSi -u ${user}:${password} -F cmd=install http://${ip}:4502/crx/packmgr/service/.json${packagePass}
}

################################################
# 処理
################################################

echo "AemContentMigration 移行作業を開始します。" >> ${LOG_FILE}
echo "`date +"%Y/%m/%d-%H:%M:%S"`" >> ${LOG_FILE}

# パスリスト確認
if [ ! -r ${PATH_LIST} ]; then
    # 存在しない場合終了
    echo "移行作業失敗しました。"
    echo "パッケージのパスリストが存在しないか、読み込み権限がありません。" >> ${LOG_FILE}
    exit 1
fi

# ダウンロードディレクトリ確認
if [ ! -d ${TEMP_DOWNLOAD_DIR} ]; then
    # 存在しない場合作成
    mkdir -p ${TEMP_DOWNLOAD_DIR}
fi

_cnt=0 # カウンター

cat ${PATH_LIST} | grep -v "^#" | while read _line
do
    if [ "${_line}" = "" ]; then
        continue
    fi
    _cnt=$(( _cnt + 1 ))
    echo "${_cnt}番目の作業を開始します。" >> ${LOG_FILE}

    # ビルド
    echo 'start buildPackage '${_line} >> ${LOG_FILE}
    buildPackage  ${USER63} ${PASSWORD63} ${IP63} ${_line} >> ${LOG_FILE}
    echo "" >> ${LOG_FILE} # 改行用
    # ダウンロード
    echo 'start downloadPackage '${_line} >> ${LOG_FILE}
    downloadPackage ${USER63} ${PASSWORD63} ${IP63} ${_line} "${TEMP_DOWNLOAD_DIR}/downloadPackage_${EXECUTION_DATE}_${_cnt}.zip" >> ${LOG_FILE}
    echo "" >> ${LOG_FILE}
    # アップロード
    echo 'start uploadPackage '${_line} >> ${LOG_FILE}
    uploadPackage ${USER65} ${PASSWORD65} ${IP65} "${TEMP_DOWNLOAD_DIR}/downloadPackage_${EXECUTION_DATE}_${_cnt}.zip" >> ${LOG_FILE}
    echo "" >> ${LOG_FILE}
    # インストール
    echo 'start installPackage '${_line} >> ${LOG_FILE}
    installPackage ${USER65} ${PASSWORD65} ${IP65} ${_line} >> ${LOG_FILE};
    echo "" >> ${LOG_FILE}

    echo "${_cnt}番目の作業を終了します。" >> ${LOG_FILE}

done

echo "移行作業終了しました。" >> ${LOG_FILE}
echo "`date +"%Y/%m/%d-%H:%M:%S"`" >> ${LOG_FILE}
exit 0
