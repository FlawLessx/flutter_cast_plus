import 'dart:io';

import 'cast_channel.dart';

class MediaChannel extends CastChannel {
  MediaChannel.create({
    Socket? socket,
    String? sourceId,
    String? destinationId,
    String? namespace,
  }) : super.createWithSocket(
          socket,
          sourceId: sourceId,
          destinationId: destinationId,
          namespace: namespace ?? 'urn:x-cast:com.google.cast.media',
        );
}
