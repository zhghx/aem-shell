use(function () {
    'use strict';

    let result = [{
        packagename: 'diff_path',
        total: '',
        paths: []
    }];

    let searchtree = ['/content'];

    while (searchtree.length > 0) {
        let searchpath = searchtree.pop();
        try {
            let map = new Packages.java.util.HashMap();
            map.put("type", "cq:Page");
            map.put("path", searchpath);
            map.put("daterange.property", "jcr:content/jcr:lastModified");
            map.put("daterange.lowerBound", "2011-02-21");
            map.put("orderby", "@jcr:content/cq:lastModified");
            map.put("orderby.sort", "desc");
            let searchResult = getSearchResult(map).getHits().iterator();
            while (searchResult.hasNext()) {
                result[0].paths.push(searchResult.next().getPath());
            }
        } catch (err) {
            let rootNode = resolver.getResource(searchpath);
            let childList = rootNode.getChildren();
            for (let childIdx = 0; childIdx < childList.length; childIdx++) {
                let childpath = childList[childIdx].getPath();
                searchtree.push(childpath);
            }
        }
    }

    result[0].total = result[0].paths.length

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
