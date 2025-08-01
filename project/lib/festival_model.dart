class Festival {
  final String contentid;
  final String title;
  final String addr1;
  final String eventstartdate;
  final String eventenddate;
  final String firstimage;
  final String mapx;
  final String mapy;

  Festival({
    required this.contentid,
    required this.title,
    required this.addr1,
    required this.eventstartdate,
    required this.eventenddate,
    required this.firstimage,
    required this.mapx,
    required this.mapy,
  });

  factory Festival.fromJson(Map<String, dynamic> json) {
    return Festival(
      contentid: json['contentid'] ?? '',
      title: json['title'] ?? '',
      addr1: json['addr1'] ?? '',
      eventstartdate: json['eventstartdate'] ?? '',
      eventenddate: json['eventenddate'] ?? '',
      firstimage: json['firstimage'] ?? '',
      mapx: json['mapx'] ?? '0.0',
      mapy: json['mapy'] ?? '0.0',
    );
  }
}

class FestivalDetail {
  final String contentid;
  final String title;
  final String addr1;
  final String overview;
  final String mapx;
  final String mapy;
  final String tel;
  final String homepage;
  final String firstimage;

  final String eventstartdate;
  final String eventenddate;
  final String playtime;
  final String usetimefestival;

  FestivalDetail({
    required this.contentid,
    required this.title,
    required this.addr1,
    required this.overview,
    required this.mapx,
    required this.mapy,
    required this.tel,
    required this.homepage,
    required this.firstimage,
    required this.eventstartdate,
    required this.eventenddate,
    required this.playtime,
    required this.usetimefestival,
  });

  factory FestivalDetail.fromJsons(
      Map<String, dynamic> common, Map<String, dynamic> intro) {
    return FestivalDetail(
      contentid: common['contentid'] ?? '',
      title: common['title'] ?? '제목 없음',
      addr1: common['addr1'] ?? '',
      overview: common['overview'] ?? '소개 정보가 없습니다.',
      mapx: common['mapx'] ?? '0.0',
      mapy: common['mapy'] ?? '0.0',
      tel: common['tel'] ?? '',
      homepage: common['homepage'] ?? '',
      firstimage: common['firstimage'] ?? '',
      eventstartdate: intro['eventstartdate'] ?? '',
      eventenddate: intro['eventenddate'] ?? '',
      playtime: intro['playtime'] ?? '',
      usetimefestival: intro['usetimefestival'] ?? '',
    );
  }
}

class FestivalImage {
  final String originimgurl;

  FestivalImage({required this.originimgurl});

  factory FestivalImage.fromJson(Map<String, dynamic> json) {
    return FestivalImage(originimgurl: json['originimgurl'] ?? '');
  }
}
