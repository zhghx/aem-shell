/**
 * コラム情報（開催中・開催予定・会期未入力or更新日順）を取得する。
 * TOPページ・フロアガイドで使用
 * @return {Array} json array
 */
use(function () {
  'use strict';

  // 定数定義
  var constants = {
    "PARENT_PATH": properties.get("parentPath"),
    "ARTICLETYPE_TAG": properties.get("articleTypeTag")
  };
  var _tagManager = resolver.adaptTo(Packages.com.day.cq.tagging.TagManager);
  var date = new Date();
  var timeToday = date.getTime();
  var strToday = getDateString(date);
  var _today = date.getFullYear() + "-" +
    ('0' + (date.getMonth() + 1)).slice(-2) + "-" +
    ('0' + date.getDate()).slice(-2) + "T" +
    ('0' + date.getHours()).slice(-2) + ":" +
    ('0' + date.getMinutes()).slice(-2);

  date.setDate(date.getDate() + 1);
  var _tommorow = date.getFullYear() + "-" +
    ('0' + (date.getMonth() + 1)).slice(-2) + "-" +
    ('0' + date.getDate()).slice(-2);

  var defaultEndDate = 0;
  var param = request.getRequestParameter("ded");
  if (param) {
    var ded = param.getString();
    if (ded == '1' || ded == '2' || ded == '3') {
      defaultEndDate = parseInt(ded);
    }
  }
  var holidayJson = '/content/dam/settings/holidays.json';
  var holidayList = null;
  var _pageList = [];

  if (properties.orderby == 'period') {
    // 開催中
    setSearchResult("on", makeQueryEventOn());
    // 開催予定
    setSearchResult("next", makeQueryEventNext());
    // 会期なし
    setSearchResult("always", makeQueryEventAlways());
    // 会期終了
    if (!properties.hideEnded) {
      setSearchResult("end", makeQueryEventEnd());
    }
  } else {
    setSearchResult("", makeQuery());
    if (properties.orderby == 'displayPublishedDate') {
      _pageList.sort(function (a, b) {
        if (a.lastModifiedSort > b.lastModifiedSort) return -1;
        if (a.lastModifiedSort < b.lastModifiedSort) return 1;
        return 0;
      });
    } 
    if (properties.orderby == 'data') {
      _pageList.sort(function (a, b) {
        if (a.dateFromSort> b.dateFromSort) return -1;
        if (a.dateFromSort< b.dateFromSort) return 1;
        if (a.dataToSort> b.dataToSort) return -1;
        if (a.dataToSort< b.dataToSort) return 1;
        if (a.lastModifiedSort > b.lastModifiedSort) return -1;
        if (a.lastModifiedSort < b.lastModifiedSort) return 1;
        return 0;
      });
    }
  }

  if (properties.count) {
    _pageList = _pageList.splice(0, properties.count);
  }

  return _pageList;

  /**
   * 検索結果から、ノードを取得しデータをJSON化
   * @param schedule
   * @param list
   * @return {map} QueryBuilder api query
   */
  function toJson(schedule, list) {

    for (var i = 0; i < list.length; i++) {
      var page = pageManager.getContainingPage(list[i]);
      var resource = resolver.getResource(list[i] + "/jcr:content/root/condition");
      if (!resource) {
        continue;
      }
      var conditionNode = resource.adaptTo(Packages.javax.jcr.Node);
      var pageNode = resolver.getResource(list[i]).adaptTo(Packages.javax.jcr.Node);
      var jcrNode = resolver.getResource(list[i] + "/jcr:content").adaptTo(Packages.javax.jcr.Node);

      var image = '';
      var imageNode = resolver.getResource(list[i] + "/jcr:content/image");
      if (imageNode) {
        imageNode = imageNode.adaptTo(Packages.javax.jcr.Node);
        if (imageNode.hasProperty("fileReference")) {
          var imageProp = imageNode.getProperty("fileReference");
          if (imageProp.isMultiple()) {
            var images = imageProp.getValues();
            image = images[0].getString();
          } else {
            image = imageProp.getString();
          }
          if (image) {
            image = resolver.map(image);
            image += '.transform/thumbnail/img.jpg';
          }
        }
      }
      var navTitle = '';
      if (jcrNode.hasProperty("navTitle")) {
        var pageProp = jcrNode.getProperty("navTitle");
        if (pageProp.isMultiple()) {
          var values = pageProp.getValues();
          navTitle = values[0].getString();
        } else {
          navTitle = page.properties.navTitle;
        }
      }
      var text = conditionNode.text ? conditionNode.text.replace(/\r\n/g, "<br />") : "";
      
      // 開始日
      var dateFrom;
      var dateFromSort;
      var hasDateFrom = false;
      if (conditionNode.hasProperty("dateFrom")) {
        dateFrom = new Date(conditionNode.getProperty("dateFrom").getDate());
        dateFromSort = Date.parse(conditionNode.getProperty("dateFrom"));
        hasDateFrom = true;
      } else {
        dateFrom = new Date(pageNode.getProperty("jcr:created").getDate());
        dateFromSort = Date.parse(pageNode.getProperty("jcr:created"));
      }
      // 終了日
      var dateTo;
      var dateToSort;
      var hasDateTo = false;
      if (conditionNode.hasProperty("dateTo")) {
        dateTo = new Date(conditionNode.getProperty("dateTo").getDate());
        dateToSort =  Date.parse(conditionNode.getProperty("dateTo"));
        hasDateTo = true;
      } else if (defaultEndDate > 0) {
        dateTo = getMonthLater(dateFrom, defaultEndDate);
        dateToSort = Date.parse(dateTo);
      }

      // 終了判別
      if (properties.orderby == 'period' && properties.hideEnded && dateTo && dateTo.getTime() < timeToday) {
        continue;
      }
      // 表示・ソート判定用公開日
      var lastModified = new Date(jcrNode.getProperty("cq:lastModified").getDate());
      var lastModifiedSort = Date.parse(lastModified);
      if (properties.orderby == 'displayPublishedDate' && conditionNode.hasProperty("displayPublishedDate")) {
          lastModified = new Date(conditionNode.getProperty("displayPublishedDate").getDate());
          lastModifiedSort = Date.parse(lastModified);
      }
      // 会期
      var datePattern = '';
      if (hasDateFrom && hasDateTo) {
        if (getDateString(dateFrom) == getDateString(dateTo)) {
          datePattern = 'oneday';
        } else {
          datePattern = 'fromto';
        }
      } else if (hasDateFrom) {
        datePattern = 'from';
      } else if (hasDateTo) {
        datePattern = 'to';
      }

      var json = {
        "schedule": schedule,
        "navTitle": replaceIllegalCharacter(navTitle),
        "path": resolver.map(list[i]),
        "dateFrom": dateFrom,
        "dateTo": dateTo,
        "datePattern": datePattern,
        "holidayFrom": getHoliday(dateFrom),
        "holidayTo": getHoliday(dateTo),
        "image": image,
        "text": text.replace(/<[^>]*>/g, '').replace(/\\/g, ''),
        "categoryTag": getTagValue(conditionNode.categoryTag),
        "floorTag": getTagValue(conditionNode.floorTag),
        "articleTypeTag": conditionNode.articleTypeTag,
        "genreTag": getTagValue(conditionNode.genreTag),
        "optionTag": getTagValue(conditionNode.optionTag),
        "lastModified": lastModified,
        "dateFromSort":dateFromSort,
        "dateToSort":dateToSort,
        "lastModifiedSort":lastModifiedSort
      };
      _pageList.push(json);
    }
  }

  /**
   * 開催中のイベント取得用のクエリー作成
   * @return {map} QueryBuilder api query
   */
  function makeQueryEventOn() {
    var map = new Packages.java.util.HashMap();
    var prop = 0;
    var tags = properties.tags;

    map.put("p.limit", "-1");
    map.put("type", "cq:Page");


    if (constants.PARENT_PATH instanceof Array) {
      prop++;
      map.put(prop.toString() + "_group.p.or", "true");
      for (var i = 0; i < constants.PARENT_PATH.length; i++) {
        map.put(prop +"_group." + (i + 1).toString() + "_path", constants.PARENT_PATH[i]);
      }
    } else if (constants.PARENT_PATH) {
      map.put("path", constants.PARENT_PATH);
    }


    prop++;
    map.put(prop + "_property", "jcr:content/root/condition/articleTypeTag");
    map.put(prop + "_property.value", constants.ARTICLETYPE_TAG);

    if(properties.storeApps){
        prop++;
        map.put(prop + "_group.p.or", "true");
		map.put(prop +"_group.1_property", "jcr:content/root/condition/storeAppsExcludeFlag");
    	map.put(prop +"_group.1_property.operation", "like");
    	map.put(prop +"_group.1_property.value", "false");
		map.put(prop +"_group.2_property", "jcr:content/root/condition/storeAppsExcludeFlag");
    	map.put(prop +"_group.2_property.operation", "not");
    	map.put(prop +"_group.2_property.value", "%_%");
    }

    if (tags) {
      prop++;
      map.put(prop +"_group.p.or", "true");
      map.put(prop +"_group.1_property", "jcr:content/root/condition/categoryTag");
      map.put(prop +"_group.2_property", "jcr:content/root/condition/floorTag");
      map.put(prop +"_group.3_property", "jcr:content/root/condition/shopTag");
      map.put(prop +"_group.4_property", "jcr:content/root/condition/genreTag");
      map.put(prop +"_group.5_property", "jcr:content/root/condition/optionTag");
      map.put(prop +"_group.6_property", "jcr:content/root/condition/serviceTag");
      map.put(prop +"_group.7_property", "jcr:content/root/condition/brandTag");

      for (var i = 0; i < tags.length; i++) {
        map.put(prop +"_group.1_property." + i + "_value", tags[i]);
        map.put(prop +"_group.2_property." + i + "_value", tags[i]);
        map.put(prop +"_group.3_property." + i + "_value", tags[i]);
        map.put(prop +"_group.4_property." + i + "_value", tags[i]);
        map.put(prop +"_group.5_property." + i + "_value", tags[i]);
        map.put(prop +"_group.6_property." + i + "_value", tags[i]);
        map.put(prop +"_group.7_property." + i + "_value", tags[i]);
      }
    }

    prop++;
    map.put(prop +"_group.p.or", "true");
    map.put(prop +"_group.1_group.p.or", "false");
    map.put(prop +"_group.1_group.1_daterange.property", "jcr:content/root/condition/dateFrom");
    map.put(prop +"_group.1_group.1_daterange.upperBound", _today);
    map.put(prop +"_group.1_group.2_daterange.property", "jcr:content/root/condition/dateTo");
    map.put(prop +"_group.1_group.2_daterange.lowerBound", _today);
    map.put(prop +"_group.2_group.p.or", "false");
    map.put(prop +"_group.2_group.1_daterange.property", "jcr:content/root/condition/dateFrom");
    map.put(prop +"_group.2_group.1_daterange.upperBound", _today);
    map.put(prop +"_group.2_group.2_property", "jcr:content/root/condition/dateTo");
    map.put(prop +"_group.2_group.2_property.operation", "exists");
    map.put(prop +"_group.2_group.2_property.value", "false");
    map.put(prop +"_group.3_group.p.or", "false");
    map.put(prop +"_group.3_group.property", "jcr:content/root/condition/dateFrom");
    map.put(prop +"_group.3_group.property.operation", "exists");
    map.put(prop +"_group.3_group.property.value", "false");
    map.put(prop +"_group.3_group.daterange.property", "jcr:content/root/condition/dateTo");
    map.put(prop +"_group.3_group.daterange.lowerBound", _today);

    map.put("1_orderby", "@jcr:content/root/condition/eventscale");
    map.put("2_orderby", "@jcr:content/root/condition/dateFrom");
    map.put("2_orderby.sort", "desc");
    map.put("3_orderby", "@jcr:content/root/condition/dateTo");
    map.put("4_orderby", "@jcr:content/root/condition/articleTypeTag");
    map.put("5_orderby", "@jcr:content/cq:lastModified");
    map.put("5_orderby.sort", "desc");

    return map;
  }

  /**
   * 開催予定のイベント取得用のクエリー作成
   * @return {map} QueryBuilder api query
   */
  function makeQueryEventNext() {
    var map = new Packages.java.util.HashMap();
    var prop = 0;
    var tags = properties.tags;

    map.put("p.limit", "-1");
    map.put("type", "cq:Page");

    if (constants.PARENT_PATH instanceof Array){
    prop++;
    map.put(prop.toString() + "_group.p.or", "true");
    for (var i = 0; i < constants.PARENT_PATH.length; i++){
    map.put(prop + "_group." + (i + 1).toString() + "_path" , constants.PARENT_PATH[i] );
        }
     }else if (constants.PARENT_PATH) {
    map.put("path", constants.PARENT_PATH);
     }


    prop++;
    map.put(prop + "_property", "jcr:content/root/condition/articleTypeTag");
    map.put(prop + "_property.value", constants.ARTICLETYPE_TAG);

    if(properties.storeApps){
        prop++;
        map.put(prop +"_group.p.or", "true");
		map.put(prop +"_group.1_property", "jcr:content/root/condition/storeAppsExcludeFlag");
    	map.put(prop +"_group.1_property.operation", "like");
    	map.put(prop +"_group.1_property.value", "false");
		map.put(prop +"_group.2_property", "jcr:content/root/condition/storeAppsExcludeFlag");
    	map.put(prop +"_group.2_property.operation", "not");
    	map.put(prop +"_group.2_property.value", "%_%");
    }

    if (tags) {
      prop++;
      map.put(prop +"_group.p.or", "true");
      map.put(prop +"_group.1_property", "jcr:content/root/condition/categoryTag");
      map.put(prop +"_group.2_property", "jcr:content/root/condition/floorTag");
      map.put(prop +"_group.3_property", "jcr:content/root/condition/shopTag");
      map.put(prop +"_group.4_property", "jcr:content/root/condition/genreTag");
      map.put(prop +"_group.5_property", "jcr:content/root/condition/optionTag");
      map.put(prop +"_group.6_property", "jcr:content/root/condition/serviceTag");
      map.put(prop +"_group.7_property", "jcr:content/root/condition/brandTag");

      for (var i = 0; i < tags.length; i++) {
        map.put(prop +"_group.1_property." + i + "_value", tags[i]);
        map.put(prop +"_group.2_property." + i + "_value", tags[i]);
        map.put(prop +"_group.3_property." + i + "_value", tags[i]);
        map.put(prop +"_group.4_property." + i + "_value", tags[i]);
        map.put(prop +"_group.5_property." + i + "_value", tags[i]);
        map.put(prop +"_group.6_property." + i + "_value", tags[i]);
        map.put(prop +"_group.7_property." + i + "_value", tags[i]);
      }
    }

    prop++;
    map.put(prop +"_group.p.or", "true");
    map.put(prop +"_group.1_daterange.property", "jcr:content/root/condition/dateFrom");
    map.put(prop +"_group.1_daterange.lowerBound", _tommorow);

    map.put("1_orderby", "@jcr:content/root/condition/eventscale");
    map.put("2_orderby", "@jcr:content/root/condition/dateFrom");
    map.put("3_orderby", "@jcr:content/root/condition/dateTo");
    map.put("4_orderby", "@jcr:content/root/condition/articleTypeTag");
    map.put("5_orderby", "@jcr:content/cq:lastModified");
    map.put("5_orderby.sort", "desc");

    return map;
  }

  /**
   * 会期無しのイベント取得用のクエリー作成
   * @return {map} QueryBuilder api query
   */
  function makeQueryEventAlways() {
    var map = new Packages.java.util.HashMap();
    var prop = 0;
    var tags = properties.tags;

    map.put("p.limit", "-1");
    map.put("type", "cq:Page");

    if (constants.PARENT_PATH instanceof Array){
    prop++;
    map.put(prop.toString() + "_group.p.or", "true");
    for (var i = 0; i < constants.PARENT_PATH.length; i++){
    map.put(prop + "_group." + (i + 1).toString() + "_path", constants.PARENT_PATH[i]);
        }
     }else if (constants.PARENT_PATH) {
    map.put("path", constants.PARENT_PATH);
     }


    prop++;
    map.put(prop + "_property", "jcr:content/root/condition/articleTypeTag");
    map.put(prop + "_property.value", constants.ARTICLETYPE_TAG);

    if(properties.storeApps){
        prop++;
        map.put(prop + "_group.p.or", "true");
		map.put(prop +"_group.1_property", "jcr:content/root/condition/storeAppsExcludeFlag");
    	map.put(prop +"_group.1_property.operation", "like");
    	map.put(prop +"_group.1_property.value", "false");
		map.put(prop +"_group.2_property", "jcr:content/root/condition/storeAppsExcludeFlag");
    	map.put(prop +"_group.2_property.operation", "not");
    	map.put(prop +"_group.2_property.value", "%_%");
    }

    if (tags) {
      prop++;
      map.put(prop +"_group.p.or", "true");
      map.put(prop +"_group.1_property", "jcr:content/root/condition/categoryTag");
      map.put(prop +"_group.2_property", "jcr:content/root/condition/floorTag");
      map.put(prop +"_group.3_property", "jcr:content/root/condition/shopTag");
      map.put(prop +"_group.4_property", "jcr:content/root/condition/genreTag");
      map.put(prop +"_group.5_property", "jcr:content/root/condition/optionTag");
      map.put(prop +"_group.6_property", "jcr:content/root/condition/serviceTag");
      map.put(prop +"_group.7_property", "jcr:content/root/condition/brandTag");

      for (var i = 0; i < tags.length; i++) {
        map.put(prop +"_group.1_property." + i + "_value", tags[i]);
        map.put(prop +"_group.2_property." + i + "_value", tags[i]);
        map.put(prop +"_group.3_property." + i + "_value", tags[i]);
        map.put(prop +"_group.4_property." + i + "_value", tags[i]);
        map.put(prop +"_group.5_property." + i + "_value", tags[i]);
        map.put(prop +"_group.6_property." + i + "_value", tags[i]);
        map.put(prop +"_group.7_property." + i + "_value", tags[i]);
      }
    }

    prop++;
    map.put(prop +"_group.p.or", "false");
    map.put(prop +"_group.1_property", "jcr:content/root/condition/dateFrom");
    map.put(prop +"_group.1_property.operation", "exists");
    map.put(prop +"_group.1_property.value", "false");
    map.put(prop +"_group.2_property", "jcr:content/root/condition/dateTo");
    map.put(prop +"_group.2_property.operation", "exists");
    map.put(prop +"_group.2_property.value", "false")
    map.put("1_orderby", "@jcr:content/root/condition/eventscale");
    map.put("2_orderby", "@jcr:content/root/condition/articleTypeTag");
    map.put("3_orderby", "@jcr:content/cq:lastModified");
    map.put("3_orderby.sort", "desc");

    return map;
  }

   /**
   * 終了済みのイベント取得用のクエリー作成
   * @return {map} QueryBuilder api query
   */
  function makeQueryEventEnd() {
    var map = new Packages.java.util.HashMap();
    var prop = 0;
    var tags = properties.tags;

    map.put("p.limit", "-1");
    map.put("type", "cq:Page");

    if (constants.PARENT_PATH instanceof Array){
    prop++;
    map.put(prop.toString() + "_group.p.or", "true");
    for (var i = 0; i < constants.PARENT_PATH.length; i++){
    map.put(prop + "_group." + (i + 1).toString() + "_path" , constants.PARENT_PATH[i] );
        }
     }else if (constants.PARENT_PATH) {
    map.put("path", constants.PARENT_PATH);
     }


    prop++;
    map.put(prop + "_property", "jcr:content/root/condition/articleTypeTag");
    map.put(prop + "_property.value", constants.ARTICLETYPE_TAG);

    if(properties.storeApps){
        prop++;
        map.put(prop +"_group.p.or", "true");
		map.put(prop +"_group.1_property", "jcr:content/root/condition/storeAppsExcludeFlag");
    	map.put(prop +"_group.1_property.operation", "like");
    	map.put(prop +"_group.1_property.value", "false");
		map.put(prop +"_group.2_property", "jcr:content/root/condition/storeAppsExcludeFlag");
    	map.put(prop +"_group.2_property.operation", "not");
    	map.put(prop +"_group.2_property.value", "%_%");
    }

    if (tags) {
      prop++;
      map.put(prop +"_group.p.or", "true");
      map.put(prop +"_group.1_property", "jcr:content/root/condition/categoryTag");
      map.put(prop +"_group.2_property", "jcr:content/root/condition/floorTag");
      map.put(prop +"_group.3_property", "jcr:content/root/condition/shopTag");
      map.put(prop +"_group.4_property", "jcr:content/root/condition/genreTag");
      map.put(prop +"_group.5_property", "jcr:content/root/condition/optionTag");
      map.put(prop +"_group.6_property", "jcr:content/root/condition/serviceTag");
      map.put(prop +"_group.7_property", "jcr:content/root/condition/brandTag");

      for (var i = 0; i < tags.length; i++) {
        map.put(prop +"_group.1_property." + i + "_value", tags[i]);
        map.put(prop +"_group.2_property." + i + "_value", tags[i]);
        map.put(prop +"_group.3_property." + i + "_value", tags[i]);
        map.put(prop +"_group.4_property." + i + "_value", tags[i]);
        map.put(prop +"_group.5_property." + i + "_value", tags[i]);
        map.put(prop +"_group.6_property." + i + "_value", tags[i]);
        map.put(prop +"_group.7_property." + i + "_value", tags[i]);
      }
    }

    prop++;
    map.put(prop +"_group.p.or", "true");
    map.put(prop +"_group.1_daterange.property", "jcr:content/root/condition/dateTo");
    map.put(prop +"_group.1_daterange.upperBound", _today);

    map.put("1_orderby", "@jcr:content/root/condition/eventscale");
    map.put("2_orderby", "@jcr:content/root/condition/dateFrom");
    map.put("3_orderby", "@jcr:content/root/condition/dateTo");
    map.put("4_orderby", "@jcr:content/root/condition/articleTypeTag");
    map.put("5_orderby", "@jcr:content/cq:lastModified");
    map.put("5_orderby.sort", "desc");

    return map;
  }

  /**
   * 最終更新日順コラム取得用のクエリー作成
   * @return {map} QueryBuilder api query
   */
  function makeQuery() {
    var map = new Packages.java.util.HashMap();
    var prop = 0;
    var tags = properties.tags;

    if (properties.count) { 
      map.put("p.limit", properties.count+"");
    } else {
      map.put("p.limit", "-1");
    }

    map.put("type", "cq:Page");

    if (constants.PARENT_PATH instanceof Array){
        prop++;
        map.put(prop.toString() + "_group.p.or", "true"); 
        for (var i = 0; i < constants.PARENT_PATH.length; i++){
            map.put(prop + "_group." + (i + 1).toString() + "_path" , constants.PARENT_PATH[i] );
        }
    }else if (constants.PARENT_PATH) {
        map.put("path", constants.PARENT_PATH);
    }

    prop++;
    map.put(prop +"_property", "jcr:content/root/condition/articleTypeTag");
    map.put(prop +"_property.value", constants.ARTICLETYPE_TAG);

    if(properties.storeApps){
        prop++;
        map.put(prop +"_group.p.or", "true");
		map.put(prop +"_group.1_property", "jcr:content/root/condition/storeAppsExcludeFlag");
    	map.put(prop +"_group.1_property.operation", "like");
    	map.put(prop +"_group.1_property.value", "false");
		map.put(prop +"_group.2_property", "jcr:content/root/condition/storeAppsExcludeFlag");
    	map.put(prop +"_group.2_property.operation", "not");
    	map.put(prop +"_group.2_property.value", "%_%");
    }

    if (tags) {
      prop++;
      map.put(prop +"_group.p.or", "true");
      map.put(prop +"_group.1_property", "jcr:content/root/condition/categoryTag");
      map.put(prop +"_group.2_property", "jcr:content/root/condition/floorTag");
      map.put(prop +"_group.3_property", "jcr:content/root/condition/shopTag");
      map.put(prop +"_group.4_property", "jcr:content/root/condition/genreTag");
      map.put(prop +"_group.5_property", "jcr:content/root/condition/optionTag");
      map.put(prop +"_group.6_property", "jcr:content/root/condition/serviceTag");
      map.put(prop +"_group.7_property", "jcr:content/root/condition/brandTag");

      for (var i = 0; i < tags.length; i++) {
           log.error("tags[i]"+i+":"+tags[i]);
        map.put(prop +"_group.1_property." + i + "_value", tags[i]);
        map.put(prop +"_group.2_property." + i + "_value", tags[i]);
        map.put(prop +"_group.3_property." + i + "_value", tags[i]);
        map.put(prop +"_group.4_property." + i + "_value", tags[i]);
        map.put(prop +"_group.5_property." + i + "_value", tags[i]);
        map.put(prop +"_group.6_property." + i + "_value", tags[i]);
        map.put(prop +"_group.7_property." + i + "_value", tags[i]);
      }
    }

      map.put("orderby", "@jcr:content/cq:lastModified");
      map.put("orderby.sort", "desc");

    return map;
  }

  /**
   * クエリー実行
   * @param map 検索用クエリー
   * @return {SearchResult} 検索結果
   */
  function getSearchResult(map) {
    if (!map) {
      return ""
    }

    log.error("SearchResult"+map);

    var PredicateGroup = Packages.com.day.cq.search.PredicateGroup;
    var mapPredicateGroup = PredicateGroup.create(map);
    var builder = resolver.adaptTo(Packages.com.day.cq.search.QueryBuilder);
    var session = resolver.adaptTo(Packages.javax.jcr.Session);
    var query = builder.createQuery(mapPredicateGroup, session);

    return query.getResult();
  }

  /**
   * クエリー結果取得
   * @param schedule 検索用クエリー
   * @param query 検索用クエリー
   * @return {SearchResult} 検索結果
   */
  function setSearchResult(schedule, query) {
    var searchResult = getSearchResult(query).getHits().iterator();
    var resultPath = [];
    while (searchResult.hasNext()) {
      resultPath.push(searchResult.next().getPath());
    }
    toJson(schedule, resultPath);
  }

  /**
   * タグ情報の取得
   * @param tagIDs 対象のタグID
   * @return {array} json array { "id" : "isetan:/../.id", "title" : "title.."} of tag info
   */
  function getTagValue(tagIDs) {

    if (!tagIDs) {
      return ""
    }

    var IDs = [];
    if (!Array.isArray(tagIDs)) {
      IDs.push(tagIDs);
    } else {
      IDs = tagIDs;
    }

    var tagsjson = [];
    for (var n = 0; n < IDs.length; n++) {
      var tag = _tagManager.resolve(IDs[n]);
      var tagjson;
      if (tag != null) {
        var resource = resolver.getResource(tag);
        var tagNode = resource.adaptTo(Packages.javax.jcr.Node);
        tagjson = {
          "id": tag.getTagID(),
          "title": tagNode['jcr:title']
        };
      } else {
        tagjson = {
          "id": "",
          "title": ""
        };
      }
      tagsjson.push(tagjson);
    }
    return tagsjson;
  }

  /**
   * 特殊文字の置換
   * @param str 対象の文字列
   * @return str
   */
  function replaceIllegalCharacter(str) {
    if (str) {
      str = str + ('');
      str = str.replace(/\n/g, '')
        .replace(/\r/g, '')
        .replace(/\t/g, '')
        .replace(/\b/g, '')
        .replace(/\f/g, '')
        .replace(/\\/g, '')
    }
    return str;
  }
  
  /**
   * 〇か月後の日付取得
   * 
   * @param dt Dateオブジェクト
   * @param mon 〇か月
   * @return 〇か月後のDateオブジェクト
   */
  function getMonthLater(dt, mon) {
    var dtFrom = new Date(dt);
    var dtTo = new Date(dtFrom);
    dtTo.setMonth(dtTo.getMonth() + mon);
    if (dtFrom.getDate() > dtTo.getDate()) {
      dtTo.setDate(0);
    }
    return dtTo;
  }
  
  /**
   * 日付文字列(yyyy/mm/dd)取得
   * 
   * @param dt Dateオブジェクト
   * @return 日付文字列(yyyy/mm/dd)
   */
  function getDateString(dt) {
    return dt.getFullYear().toString() + "/" + ("0" + (dt.getMonth() + 1).toString()).slice(-2) + "/" + ("0" + dt.getDate().toString()).slice(-2);
  }
  
  /**
   * 祝日取得
   * 
   * @param dt Dateオブジェクト
   * @return 祝日
   */
  function getHoliday(dt) {
    if (holidayList === null) {
      holidayList = getHoidayList();
    }
    if (holidayList.length == 0) {
      return "";
    }
    if (!dt) {
      return "";
    }
    var key = getDateString(dt);
    if (holidayList[key]) {
      var str = holidayList[key].trim();
      return str ? "&middot;" + str : "";
    }
    return "";
  }

  /**
   * 祝日定義読み込み
   * 
   * @param 
   * @return 祝日定義
   */
  function getHoidayList() {
    try {
      var resource = resolver.getResource(holidayJson + "/jcr:content/renditions/original/jcr:content").adaptTo(Packages.javax.jcr.Node);
      if (!resource) {
        return {};
      }
      var data = resource.getProperty('jcr:data').getValue().toString();
      var json = JSON.parse(data);
      var ret = {};
      for (var i = 0; i < json.length; i++) {
        ret[json[i]["date"]] = json[i]["title"];
      }
      return ret;
    } catch(e) {
      log.info(e);
      return {};
    }
  }
});
