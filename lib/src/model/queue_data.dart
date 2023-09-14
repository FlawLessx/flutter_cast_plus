import 'queue_item.dart';

class QueueData {
  QueueData({
    required this.items,
    this.startIndex,
    this.currentTime,
  });

  List<QueueItem>? items;
  int? startIndex;
  double? currentTime;

  Map<String, dynamic> toChromecastJson() {
    final data = <String, dynamic>{};
    data['type'] = 'QUEUE_LOAD';
    if (startIndex != null) data['startIndex'] = startIndex;
    if (currentTime != null) data['currentTime'] = currentTime;
    data['items'] = items?.map((e) => e.toChromecastMap()).toList();
    return data;
  }

  // Map<String, dynamic> toJsonWithoutType() {
  //   final data = <String, dynamic>{};

  //   if (startIndex != null) data['startIndex'] = startIndex;
  //   data['items'] = items?.map((e) => e.toJson()).toList();
  //   return data;
  // }
}
