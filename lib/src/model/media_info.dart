class MediaInfo {
  MediaInfo({
    required this.contentId,
    required this.contentType,
    required this.streamType,
    required this.metadata,
    required this.mediaCategory,
  });
  late final String contentId;
  late final String contentType;
  late final String streamType;
  late final Metadata metadata;
  late final String mediaCategory;

  MediaInfo.fromChromecastJson(Map<String, dynamic> json) {
    contentId = json['contentId'];
    contentType = json['contentType'];
    streamType = json['streamType'];
    metadata = Metadata.fromMap(json['metadata']);
    mediaCategory = json['mediaCategory'];
  }

  Map<String, dynamic> toChromecastJson() {
    final data = <String, dynamic>{};
    data['contentId'] = contentId;
    data['contentType'] = contentType;
    data['streamType'] = streamType;
    data['metadata'] = metadata.toMap();
    data['mediaCategory'] = mediaCategory;
    return data;
  }
}

class Metadata {
  Metadata({
    required this.metadataType,
    required this.images,
    required this.title,
  });
  late final int metadataType;
  late final List<String> images;
  late final String title;

  Metadata.fromMap(Map<String, dynamic> json) {
    metadataType = json['metadataType'];
    images = List.castFrom<dynamic, String>(json['images']);
    title = json['title'];
  }

  Map<String, dynamic> toMap() {
    final data = <String, dynamic>{};
    data['metadataType'] = metadataType;
    data['images'] = images;
    data['title'] = title;
    return data;
  }
}
