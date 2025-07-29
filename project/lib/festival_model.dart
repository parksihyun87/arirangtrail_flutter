class Festival {
  final String title;
  final String addr1;
  final String addr2;
  final String contenttypeid;
  final String contentid;
  final String eventstartdate;
  final String eventenddate;
  final String firstimage;
  final String firstimage2;
  final String tel;

  Festival({
    required this.title,
    required this.addr1,
    required this.addr2,
    required this.contenttypeid,
    required this.contentid,
    required this.eventstartdate,
    required this.eventenddate,
    required this.firstimage,
    required this.firstimage2,
    required this.tel,
  });

  factory Festival.fromJson(Map<String, dynamic> json) {
    return Festival(
      title: json['title'] ?? '',
      addr1: json['addr1'] ?? '',
      addr2: json['addr2'] ?? '',
      contenttypeid: json['contenttypeid'] ?? '',
      contentid: json['contentid'] ?? '',
      eventstartdate: json['eventstartdate'] ?? '',
      eventenddate: json['eventenddate'] ?? '',
      firstimage: json['firstimage'] ?? '',
      firstimage2: json['firstimage2'] ?? '',
      tel: json['tel'] ?? '',
    );
  }
}
