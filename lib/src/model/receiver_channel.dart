import 'dart:io';

import 'cast_channel.dart';

class ReceiverChannel extends CastChannel {
  ReceiverChannel.create(
    Socket? socket, {
    String? sourceId,
    String? destinationId,
    String? namespace,
  }) : super.createWithSocket(
          socket,
          sourceId: sourceId ?? 'sender-0',
          destinationId: destinationId ?? 'receiver-0',
          namespace: namespace ?? 'urn:x-cast:com.google.cast.receiver',
        );
}
