use(function () {
    'use strict';

    // 定数定義
    // storePathは複数入力、フォマード：検索パス,店舗階層、タイプ：string
    // maxは一つのパッケージに最大ページ数、タイプ：string
    var constants = {
        "SEARCH_PATH": '/content',
        "MAX": 500
    };

    //int に転換
    var searchMax = parseInt(constants.MAX);

    //検索リスト
    var searchlist = [];

    //検索リスト取得、デフォルトは/content,2
    if (constants.SEARCH_PATH instanceof Array) {
        searchlist = constants.SEARCH_PATH
    } else {
        searchlist = ["/content,2"];
    }


    //結果リスト
    var packageslist = [];

    //検索サポートリスト
    var searchtree = [];

    //今のパッケージ名前
    var nowpackage = "";

    //パッケージ番号
    var count = 1;

    //出力内容
    var packagename = "";
    var paths = [];
    var total = 0;

    var testChild = null;

    //検索開始
    var i = 0;
    for (i = 0; i < searchlist.length; i++) {

        //検索パスと店舗階層の取得
        var info = searchlist[i].split(',');
        var firstPath = info[0];
        var shopDepth = parseInt(info[1]);

        //親パスから
        searchtree.push(firstPath);

        while (searchtree.length > 0) {

            //出力フォマード
            var description = {
                "packagename": "",
                "paths": [],
                "total": 0
            };

            //一つのパスを取得
            var searchpath = searchtree[searchtree.length - 1];
            searchtree.pop();

            //該当パス配下のページ数を取得
            var pageNumber = checkPageNumber(searchpath);

            //最大ページ数を超えた場合、下の階層を検索
            if (pageNumber > searchMax) {
                var rootNode = resolver.getResource(searchpath);
                var childList = rootNode.getChildren();
                var childIdx = 0;
                for (childIdx = 0; childIdx < childList.length; childIdx++) {
                    var child = childList[childIdx];
                    //チェック改修時間
                    var date = new Date('2021-02-21');
                    var modifiedDateStr = child.getAttribute('jcr:content/@jcr:lastModified');
                    var modifiedDate = new Date(modifiedDateStr);
                    if (modifiedDate.getTime() > date.getTime()) {
                        var childpath = child.getPath();
                        searchtree.push(childpath);
                    }
                    var createDateStr = child.getAttribute('jcr:content/@jcr:created');
                    var createDate = new Date(createDateStr);
                    if (createDate.getTime() > date.getTime()) {
                        var childpath = child.getPath();
                        searchtree.push(childpath);
                    }
                }
            } else {
                //合わせて最大ページ数を超えた場合
                //該当パス以外前に検索出来たパスをパッケージにする
                if ((total + pageNumber) > searchMax) {
                    packagename = createPackageName(paths[0], shopDepth);
                    description.packagename = packagename;
                    description.paths = paths;
                    description.total = total;
                    packageslist.push(description);
                    packagename = "";
                    paths = [searchpath];
                    total = pageNumber;
                } else {
                    //パッケージのフィルタに入れる
                    paths.push(searchpath);
                    total += pageNumber;
                }
            }
        }

        //残り部分パッケージにする
        if (total != 0 || paths.length != 0) {
            var description = {
                "packagename": "",
                "paths": [],
                "total": 0
            };

            packagename = createPackageName(paths[0], shopDepth);
            description.packagename = packagename;
            description.paths = paths;
            description.total = total;
            packageslist.push(description);
        }

        //後処理
        packagename = "";
        paths = [];
        total = 0;

    }

    return {content: packageslist, testLog: JSON.stringify(testChild)};


    /*関数：あるパス配下のページを取得
 　　querybuilderを利用
   　path=検索パス
     type=cq:Page
 　　*/
    function checkPageNumber(path) {
        var map = new Packages.java.util.HashMap();

        map.put("type", "cq:Page");
        map.put("path", path);

        var PredicateGroup = Packages.com.day.cq.search.PredicateGroup;
        var mapPredicateGroup = PredicateGroup.create(map);
        var builder = resolver.adaptTo(Packages.com.day.cq.search.QueryBuilder);
        var session = resolver.adaptTo(Packages.javax.jcr.Session);
        var query = builder.createQuery(mapPredicateGroup, session);
        var result = query.getResult();

        return result.getTotalMatches();
    }

    /*関数：パッケージ名前を作成
　　　フィルターの第一のパスを元にする
　　　MG_[店舗名まで]_[番号]
　　*/
    function createPackageName(path, shopDepth) {
        path = path.toString();
        if (path.indexOf("/content/") != -1) {
            path = path.substring(9);
        }
        var namelist = path.split('/');
        var name = "MG_";
        var i = 0;
        var namelength = shopDepth < namelist.length ? shopDepth : namelist.length
        for (i = 0; i < namelength; i++) {
            name = name.concat(namelist[i] + "_");
        }
        if (name.equals(nowpackage)) {
            count++;
            name = name.concat(count.toString());

        } else {
            count = 1;
            name = name.concat(count.toString());
        }
        nowpackage = name.substring(0, name.length - 1);

        return name;
    }

});
