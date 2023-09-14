import 'text_track_style.dart';
import 'track.dart';

class CastMedia {
  late final String? contentId;
  String? title;
  String? subtitle;
  bool autoPlay = true;
  late double position;
  late double playbackRate;
  late String contentType;
  List<String>? images;
  late String streamType;
  TextTrackStyle? textTrackStyle;
  List<Track>? tracks;
  Map<String, dynamic>? customData;

  CastMedia({
    this.contentId,
    this.title,
    this.subtitle,
    this.autoPlay = true,
    this.position = 0.0,
    this.playbackRate = 1.0,
    this.contentType = 'video/mp4',
    this.images,
    this.tracks,
    this.textTrackStyle,
    this.streamType = 'BUFFERED',
    this.customData,
  }) {
    images ??= [];
  }

  CastMedia.fromChromecastMap(Map<String, dynamic> json) {
    contentId = json['contentId'];
    title = json['title'];
    subtitle = json['subtitle'];
    autoPlay = json['autoPlay'];
    position = json['position'];
    playbackRate = json['playbackRate'];
    contentType = json['contentType'];
    customData = json['customData'];
    images = json['images'];
    textTrackStyle = TextTrackStyle.fromCromecastMap(json['textTrackStyle']);
    tracks = json['tracks'].map((e) => Track.fromChromcastMap(e)).toList();
    streamType = json['streamType'];
  }

  Map toChromeCastMap() {
    return {
      'type': 'LOAD',
      'autoPlay': autoPlay,
      'currentTime': position,
      'playbackRate': playbackRate,
      'activeTracks': [],
      'media': {
        'contentId': contentId,
        'contentType': contentType,
        'streamType': streamType,
        'textTrackStyle': textTrackStyle?.toCromecastMap(),
        'tracks': tracks?.map((e) => e.toChromeCastMap()).toList(),
        'metadata': {
          'metadataType': 0,
          'images': images?.map((image) => {'url': image}).toList(),
          'title': title,
          'subtitle': subtitle,
        },
      }
    };
  }

  Map toChromeCastQueueMap() {
    return {
      'contentId': contentId,
      'contentType': contentType,
      'streamType': streamType,
      'customData': customData,
      'textTrackStyle': textTrackStyle?.toCromecastMap(),
      'tracks': tracks?.map((e) => e.toChromeCastMap()).toList(),
      'metadata': {
        'metadataType': 0,
        'images': images?.map((image) => {'url': image}).toList(),
        'title': title,
        'subtitle': subtitle,
      },
    };
  }
}
