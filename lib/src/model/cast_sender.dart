// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'dart:math';
// import 'dart:developer' as dev;

// import 'package:flutter_cast_plus/src/model/media_info.dart';
// import 'package:flutter_cast_plus/src/proto/cast_channel.pb.dart';
// import 'package:logging/logging.dart';

// import 'cast_device.dart';
// import 'cast_media.dart';
// import 'cast_media_status.dart';
// import 'cast_session.dart';
// import 'connection_channel.dart';
// import 'hearbeat_channel.dart';
// import 'media_channel.dart';
// import 'queue_data.dart';
// import 'queue_item.dart';
// import 'receiver_channel.dart';
// import 'track.dart';

// class CastSender extends Object {
//   final log = Logger('CastSender');
//   final CastDevice device;

//   SecureSocket? _socket;

//   ConnectionChannel? _connectionChannel;
//   HeartbeatChannel? _heartbeatChannel;
//   ReceiverChannel? _receiverChannel;
//   MediaChannel? _mediaChannel;
//   String? _namespace;

//   late bool connectionDidClose;
//   Timer? _mediaCurrentTimeTimer;

//   CastSession? _castSession;
//   late StreamController<CastSession?> castSessionController;
//   late StreamController<CastMediaStatus?> castMediaStatusController;
//   late StreamController<bool?> closeController;
//   QueueData? _queueData;
//   MediaInfo? _currentMedia;

//   CastSender(this.device, {String? namespace}) {
//     castSessionController = StreamController.broadcast();
//     castMediaStatusController = StreamController.broadcast();
//     closeController = StreamController.broadcast();
//     _namespace = namespace;
//   }

//   Future<bool> connect() async {
//     connectionDidClose = false;

//     _castSession ??= CastSession(
//         sourceId: 'client-${Random().nextInt(99999)}',
//         destinationId: 'receiver-0');

//     // connect to socket
//     if (null == await _createSocket()) {
//       // log.w('Could not create socket');
//       return false;
//     }

//     _connectionChannel!.sendMessage({'type': 'CONNECT'});

//     // start heartbeat
//     _heartbeatTick();

//     return true;
//   }

//   Future<bool> reconnect({String? sourceId, String? destinationId}) async {
//     _castSession =
//         CastSession(sourceId: sourceId, destinationId: destinationId);
//     bool connected = await connect();
//     if (!connected) {
//       return false;
//     }

//     _mediaChannel = MediaChannel.create(
//         socket: _socket, sourceId: sourceId, destinationId: destinationId);
//     _mediaChannel!.sendMessage({'type': 'GET_STATUS'});

//     // now wait for the media to actually get a status?
//     bool didReconnect = await _waitForMediaStatus();
//     if (didReconnect) {
//       // log.d('reconnecting successful!');
//       try {
//         castSessionController.add(_castSession);
//       } catch (e) {
//         // log.w(
//         //     "Could not add the CastSession to the CastSession Stream Controller: events will not be triggered");
//         // log.w(e.toString());
//         // log.i("Closed? ${castSessionController.isClosed}");
//       }

//       try {
//         castMediaStatusController.add(_castSession!.castMediaStatus);
//       } catch (e) {
//         // log.w(
//         //     "Could not add the CastMediaStatus to the CastSession Stream Controller: events will not be triggered");
//         // log.w(e.toString());
//         // log.i("Closed? ${castMediaStatusController.isClosed}");
//       }
//     }
//     return didReconnect;
//   }

//   Future<bool> disconnect() async {
//     // log.i("cast_sender.disconnect()");
//     _connectionChannel?.sendMessage({
//       'type': 'CLOSE',
//     });
//     _socket?.destroy();
//     _dispose();
//     connectionDidClose = true;
//     return true;
//   }

//   void launch([String? appId]) {
//     if (null != _receiverChannel) {
//       _receiverChannel!.sendMessage({
//         'type': 'LAUNCH',
//         'appId': appId ?? 'CC1AD845',
//       });
//     }
//   }

//   void load(CastMedia media, {forceNext = true}) {
//     loadPlaylist([media], forceNext: forceNext);
//   }

//   void loadPlaylist(List<CastMedia> media,
//       {append = false, forceNext = false}) {
//     if (null != _mediaChannel) {
//       setActiveTracksIds([]);

//       // _handleContentQueue(forceNext: forceNext || !append);
//       _convertCastMediasToQueue(media, append: append, forceNext: forceNext);
//       if (_queueData != null) {
//         // dev.log('${_queueData!.toJson()}');
//         _mediaChannel!.sendMessage(_queueData!.toJson());

//         // TODO: UPDATE LIST QUEUE COMMAND
//       }
//     }
//   }

//   void play() {
//     _castMediaAction('PLAY');
//     // log.i('PLAY');
//   }

//   void pause() {
//     _castMediaAction('PAUSE');
//     // log.i('PAUSE');
//   }

//   void togglePause() {
//     // log.i("TOGGLE_PAUSE");
//     // log.i(_castSession?.castMediaStatus.toString());
//     if (true == _castSession?.castMediaStatus?.isPlaying) {
//       pause();
//     } else if (true == _castSession?.castMediaStatus?.isPaused) {
//       play();
//     }
//   }

//   void stop() {
//     _castMediaAction('STOP');
//   }

//   void seek(double time) {
//     Map<String, dynamic> map = {'currentTime': time};
//     _castMediaAction('SEEK', map);
//   }

//   void setVolume(double volume) {
//     Map<String, dynamic> map = {
//       'volume': {'level': volume, 'muted': false}
//     };
//     _castMediaAction('SET_VOLUME', map);
//   }

//   void mute() {
//     Map<String, dynamic> map = {
//       'volume': {'muted': true}
//     };
//     _castMediaAction('SET_VOLUME', map);
//   }

//   void unmute() {
//     Map<String, dynamic> map = {
//       'volume': {'muted': false}
//     };
//     _castMediaAction('SET_VOLUME', map);
//   }

//   void setPlaybackRate(double rate) {
//     Map<String, dynamic> map = {
//       "playbackRate": rate,
//       "requestId": 1,
//     };
//     _castMediaAction('SET_PLAYBACK_RATE', map);
//   }

//   void queueNext() {
//     setActiveTracksIds([]);
//     _castMediaAction('QUEUE_NEXT', {});
//   }

//   void queuePrev() {
//     setActiveTracksIds([]);
//     _castMediaAction('QUEUE_PREV', {});
//   }

//   void setRepeatMode(String mode) {
//     Map<String, dynamic> map = {
//       "repeatMode": mode,
//     };

//     _castMediaAction('QUEUE_UPDATE', map);
//   }

//   void addTrack(Track track, int index) {
//     if (_queueData != null) {
//       // Reset current tracks
//       setActiveTracksIds([]);
//       final mediaIndex = getCurrentMediaIndex();

//       for (var item in _queueData!.items!) {
//         item.itemId = null;
//       }

//       // log.v('Current Position: ${_castSession?.castMediaStatus?.position}');

//       _queueData!.items?[mediaIndex].activeTrackIds = [track.trackId!];
//       _queueData!.items?[mediaIndex].media.tracks = [track];
//       _queueData!.currentTime = _castSession?.castMediaStatus?.position;
//       _queueData!.startIndex = mediaIndex;
//       _mediaChannel!.sendMessage(_queueData!.toJson());

//       // // Better use this but not working
//       // Map<String, dynamic> map = {
//       //   "currentItemId": _castSession?.castMediaStatus?.currentItemId,
//       //   "currentTime": _castSession?.castMediaStatus?.position,
//       //   // Track in queue only loaded when jump
//       //   "jump": -1,
//       //   "items": [_queueData!.items?[mediaIndex].toJson()]
//       // };
//       // _castMediaAction('QUEUE_UPDATE', map);
//     }
//   }

//   void setActiveTracksIds(List<int> trackIds) {
//     Map<String, dynamic> trackInfoMap = {
//       "activeTrackIds": trackIds,
//     };
//     _castMediaAction('EDIT_TRACKS_INFO', trackInfoMap);
//   }

//   int getCurrentMediaIndex() {
//     int result = 0;

//     if (_queueData != null && _queueData!.items != null) {
//       for (var i = 0; i < _queueData!.items!.length; i++) {
//         if (_queueData!.items![i].media.title ==
//             _currentMedia!.metadata.title) {
//           result = i;
//           break;
//         }
//       }
//     }

//     return result != 0 ? result - 1 : result;
//   }

//   CastSession? get castSession => _castSession;

//   //
//   // Private
//   //
//   void _castMediaAction(type, [params]) {
//     params ??= {};
//     if (null != _mediaChannel && null != _castSession?.castMediaStatus) {
//       dynamic message = params
//         ..addAll({
//           'mediaSessionId': _castSession!.castMediaStatus!.sessionId,
//           'type': type,
//         });
//       _mediaChannel!.sendMessage(message);
//     }
//   }

//   void _convertCastMediasToQueue(List<CastMedia> media,
//       {append = false, forceNext = false}) {
//     List<QueueItem> queueItems = [];

//     for (var i = 0; i < media.length; i++) {
//       final element = media[i];

//       final queueItem = QueueItem(
//         media: element,
//         orderId: i,
//         preloadTime: 5,
//         activeTrackIds: [],
//       );

//       queueItems.add(queueItem);
//     }

//     if (append && _queueData != null) {
//       _queueData!.items?.addAll(queueItems);
//     } else {
//       _queueData = QueueData(items: queueItems);
//     }
//   }

//   Future<SecureSocket?> _createSocket() async {
//     if (null == _socket) {
//       try {
//         // log.d('Connecting to ${device.host}:${device.port}');

//         _socket = await SecureSocket.connect(device.host, device.port!,
//             onBadCertificate: (X509Certificate certificate) => true,
//             timeout: const Duration(seconds: 10));

//         _connectionChannel = ConnectionChannel.create(
//           _socket,
//           sourceId: _castSession!.sourceId,
//           destinationId: _castSession!.destinationId,
//           namespace: _namespace,
//         );
//         _heartbeatChannel = HeartbeatChannel.create(_socket,
//             sourceId: _castSession!.sourceId,
//             destinationId: _castSession!.destinationId);
//         _receiverChannel = ReceiverChannel.create(_socket,
//             sourceId: _castSession!.sourceId,
//             destinationId: _castSession!.destinationId);

//         _socket!.listen(_onSocketData, onDone: _dispose);
//       } catch (e) {
//         // log.d(e.toString());
//         return null;
//       }
//     }
//     return _socket;
//   }

//   void _onSocketData(List<int> event) {
//     // When receive this type try to reconnect session

//     List<int> slice = event.getRange(4, event.length).toList();

//     CastMessage message = CastMessage.fromBuffer(slice);
//     // handle the message
//     Map<String, dynamic> payloadMap = jsonDecode(message.payloadUtf8);

//     if ('PING' != payloadMap['type'] && 'PONG' != payloadMap['type']) {
//       dev.log(message.payloadUtf8);
//     }

//     if ('CLOSE' == payloadMap['type']) {
//       _dispose();
//       connectionDidClose = true;
//     }
//     if ('RECEIVER_STATUS' == payloadMap['type']) {
//       _handleReceiverStatus(payloadMap);
//     } else if ('MEDIA_STATUS' == payloadMap['type']) {
//       _handleMediaStatus(payloadMap);
//     } else if ('CLOSE' == payloadMap['type']) {
//       closeController.add(true);
//     }
//   }

//   void _handleReceiverStatus(Map payload) {
//     // log.i("_handleReceiverStatus()");
//     if (null == _mediaChannel &&
//         true == payload['status']?.containsKey('applications')) {
//       // re-create the channel with the transportId the chromecast just sent us
//       if (false == _castSession?.isConnected) {
//         _castSession = _castSession!
//           ..mergeWithChromeCastSessionMap(payload['status']['applications'][0]);
//         _connectionChannel = ConnectionChannel.create(
//           _socket,
//           sourceId: _castSession!.sourceId,
//           destinationId: _castSession!.destinationId,
//           namespace: _namespace,
//         );
//         _connectionChannel!.sendMessage({'type': 'CONNECT'});
//         _mediaChannel = MediaChannel.create(
//           socket: _socket,
//           sourceId: _castSession!.sourceId,
//           destinationId: _castSession!.destinationId,
//         );
//         _mediaChannel!.sendMessage({'type': 'GET_STATUS'});

//         try {
//           castSessionController.add(_castSession);
//         } catch (e) {
//           // log.w(
//           // "Could not add the CastSession to the CastSession Stream Controller: events will not be triggered");
//           // log.w(e.toString());
//         }
//       }
//     }
//   }

//   Future<bool> _waitForMediaStatus() async {
//     while (false == _castSession!.isConnected) {
//       await Future.delayed(const Duration(milliseconds: 100));
//       if (connectionDidClose) return false;
//     }
//     return _castSession!.isConnected;
//   }

//   void _handleMediaStatus(Map payload) {
//     if (null != payload['status']) {
//       if (_castSession != null && !_castSession!.isConnected) {
//         _castSession!.isConnected = true;
//         // _handleContentQueue();
//       }

//       if (_castSession != null && payload['status'].length > 0) {
//         _castSession!.castMediaStatus =
//             CastMediaStatus.fromChromeCastMediaStatus(payload['status'][0]);

//         if (payload['status'][0]['items'] != null && _queueData != null) {
//           for (var responseItem in payload['status'][0]['items']) {
//             for (var item in _queueData!.items!) {
//               if (item.media.contentId == responseItem['media']['contentId']) {
//                 item.itemId = responseItem['itemId'];
//               }
//             }
//           }
//         }

//         if (_castSession!.castMediaStatus!.media != null) {
//           _currentMedia = _castSession!.castMediaStatus!.media;
//         }

//         if (_castSession!.castMediaStatus!.isFinished) {
//           setActiveTracksIds([]);
//         }

//         if (_castSession!.castMediaStatus!.isPlaying) {
//           _mediaCurrentTimeTimer =
//               Timer(const Duration(seconds: 1), _getMediaCurrentTime);
//         } else if (_castSession!.castMediaStatus!.isPaused &&
//             null != _mediaCurrentTimeTimer) {
//           _mediaCurrentTimeTimer!.cancel();
//           _mediaCurrentTimeTimer = null;
//         }

//         try {
//           castMediaStatusController.add(_castSession!.castMediaStatus);
//         } catch (e) {
//           // log.w(
//           // "Could not add the CastMediaStatus to the CastSession Stream Controller: events will not be triggered");
//           // log.w(e.toString());
//           // log.i("Closed? ${castMediaStatusController.isClosed}");
//         }
//       } else {
//         // log.d("Media status is empty");
//       }
//     }
//   }

//   void _getMediaCurrentTime() {
//     if (null != _mediaChannel &&
//         true == _castSession?.castMediaStatus?.isPlaying) {
//       _mediaChannel!.sendMessage({
//         'type': 'GET_STATUS',
//       });
//     }
//   }

//   void _heartbeatTick() {
//     if (null != _heartbeatChannel) {
//       _heartbeatChannel!.sendMessage({'type': 'PING'});
//       Timer(const Duration(seconds: 5), _heartbeatTick);
//     }
//   }

//   void _dispose() {
//     // log.i("cast_sender._dispose()");
//     _socket = null;
//     _heartbeatChannel = null;
//     _connectionChannel = null;
//     _receiverChannel = null;
//     _mediaChannel = null;
//     _castSession = null;
//     _queueData = null;
//     // _contentQueue = [];
//   }
// }
