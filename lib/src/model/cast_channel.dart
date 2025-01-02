import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_cast_plus/src/utils/writer.dart';
import 'package:logger/logger.dart';

import '../proto/cast_channel.pb.dart';

abstract class CastChannel {
  final log = Logger();

  final Socket? _socket;
  final String? _sourceId;
  final String? _destinationId;
  final String? _namespace;

  CastChannel(
      this._socket, this._sourceId, this._destinationId, this._namespace);

  CastChannel.createWithSocket(Socket? socket,
      {String? sourceId, String? destinationId, String? namespace})
      : _socket = socket,
        _sourceId = sourceId,
        _destinationId = destinationId,
        _namespace = namespace;

  void sendMessageChromecast(Map payload, int requestId) async {
    payload['requestId'] = requestId;

    CastMessage castMessage = CastMessage();
    castMessage.protocolVersion = CastMessage_ProtocolVersion.CASTV2_1_0;
    castMessage.sourceId = _sourceId!;
    castMessage.destinationId = _destinationId!;
    castMessage.namespace = _namespace!;
    castMessage.payloadType = CastMessage_PayloadType.STRING;
    castMessage.payloadUtf8 = jsonEncode(payload);

    Uint8List bytes = castMessage.writeToBuffer();
    Uint32List headers = Uint32List.fromList(writeUInt32BE(
        List<int>.filled(4, 0, growable: false), bytes.lengthInBytes));
    Uint32List fullData =
        Uint32List.fromList(headers.toList()..addAll(bytes.toList()));

    if (payload['type'] != 'PING' && payload['type'] != 'GET_STATUS') {
      log.i("Send message to mediaChannel: ${jsonEncode(payload)}");
    }

    _socket!.add(fullData);
    requestId++;
  }
}
