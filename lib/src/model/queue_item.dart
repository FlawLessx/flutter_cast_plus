import 'package:flutter_cast_plus/src/model/cast_media.dart';

class QueueItem {
  QueueItem({
    this.activeTrackIds,
    this.autoplay = true,
    required this.media,
    required this.orderId,
    this.preloadTime,
    this.startTime,
    this.itemId,
  });
  List<int>? activeTrackIds;
  late final bool? autoplay;
  late final CastMedia media;
  late final int orderId;
  int? itemId;
  double? preloadTime;
  double? startTime;

  QueueItem.fromChromecastMap(Map<String, dynamic> json) {
    activeTrackIds = List.castFrom<dynamic, int>(json['activeTrackIds']);
    autoplay = json['autoplay'];
    media = CastMedia.fromChromecastMap(json['media']);
    orderId = json['orderId'];
    preloadTime = json['preloadTime'];
    startTime = json['startTime'];
  }

  Map<String, dynamic> toChromecastMap() {
    final data = <String, dynamic>{};
    data['activeTrackIds'] = activeTrackIds ?? [];
    if (autoplay != null) data['autoplay'] = autoplay;
    if (itemId != null) data['itemId'] = itemId;
    data['media'] = media.toChromeCastQueueMap();
    data['orderId'] = orderId;
    if (preloadTime != null) data['preloadTime'] = preloadTime;
    if (startTime != null) data['startTime'] = startTime;
    return data;
  }
}
