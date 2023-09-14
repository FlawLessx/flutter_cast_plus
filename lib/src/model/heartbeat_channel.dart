import 'dart:io';
import 'cast_channel.dart';

class HeartbeatChannel extends CastChannel {
  HeartbeatChannel.create(Socket? socket,
      {String? sourceId, String? destinationId, String? namespace})
      : super.createWithSocket(
          socket,
          sourceId: sourceId ?? 'sender-0',
          destinationId: destinationId ?? 'receiver-0',
          namespace: namespace ?? 'urn:x-cast:com.google.cast.tp.heartbeat',
        );
}
