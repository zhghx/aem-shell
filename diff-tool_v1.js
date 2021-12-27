use(function () {
    'use strict';

    // 定数定義
    // diffDate:  変化するまでの時間
    // onlyPage:  選択ページのみ
    // searchPath:選択パス
    var constants = {
        DIFF_DATE: properties.get("diffDate"),
        ONLY_PAGE: properties.get("onlyPage"),
        SEARCH_PATH: properties.get("searchPath")
    };

    let result = {
        packagename: 'diff_path',
        total: '',
        paths: []
    };

    // デフォルトパース
    let searchtree = [
        '/content/dam',
        '/content/experience-fragments ',
        '/etc/tags'
    ];

    if (constants.SEARCH_PATH) {
        searchtree = [constants.SEARCH_PATH]
    }

    while (searchtree.length > 0) {
        let searchpath = searchtree.pop();
        try {
            let map = new Packages.java.util.HashMap();
            map.put("path", searchpath);
            if (constants.ONLY_PAGE) {
                map.put("type", "cq:Page");
            }
            map.put("group.p.or", "true");
            map.put("group.1_daterange.property", "jcr:content/jcr:lastModified");
            map.put("group.1_daterange.lowerBound", constants.DIFF_DATE);
            map.put("group.2_daterange.property", "jcr:content/jcr:created");
            map.put("group.2_daterange.lowerBound", constants.DIFF_DATE);
            let searchResult = getSearchResult(map).getHits().iterator();
            while (searchResult.hasNext()) {
                result.paths.push(searchResult.next().getPath());
            }
        } catch (err) {
            let targetException = 'The query read or traversed more than 100000 nodes';
            if (String(err.message).indexOf(targetException)) {
                let rootNode = resolver.getResource(searchpath);
                let childList = rootNode.getChildren();
                for (let childIdx = 0; childIdx < childList.length; childIdx++) {
                    let childpath = childList[childIdx].getPath();
                    searchtree.push(childpath);
                }
            } else {
                throw err;
            }
        }
    }

    result.total = result.paths.length

    return result;

    function getSearchResult(map) {
        if (!map) {
            return ""
        }
        let PredicateGroup = Packages.com.day.cq.search.PredicateGroup;
        let mapPredicateGroup = PredicateGroup.create(map);
        let builder = resolver.adaptTo(Packages.com.day.cq.search.QueryBuilder);
        let session = resolver.adaptTo(Packages.javax.jcr.Session);
        let query = builder.createQuery(mapPredicateGroup, session);
        return query.getResult();
    }

});
