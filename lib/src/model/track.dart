class Track {
  late final String? name;
  late final String? trackContentType;
  int? trackId;
  late final String type;
  late final String trackContentId;

  Track({
    this.name,
    this.trackContentType = 'text/vtt',
    required this.trackId,
    this.type = 'TEXT',
    required this.trackContentId,
  });

  Track.fromChromcastMap(Map<String, dynamic> json) {
    name = json['name'];
    trackContentType = json['trackContentType'];
    trackId = json['trackId'];
    type = json['type'];
    trackContentId = json['trackContentId'];
  }

  Map toChromeCastMap() {
    return {
      'type': type,
      'name': name,
      'trackId': trackId,
      'trackContentType': trackContentType,
      'trackContentId': trackContentId,
      'subtype ': 'CAPTIONS'
    };
  }
}
