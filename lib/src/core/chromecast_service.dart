import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_cast_plus/src/model/cast_completer.dart';
import 'package:flutter_cast_plus/src/model/cast_media_status.dart';
import 'package:flutter_cast_plus/src/model/cast_session.dart';
import 'package:flutter_cast_plus/src/model/connection_channel.dart';
import 'package:flutter_cast_plus/src/model/heartbeat_channel.dart';
import 'package:flutter_cast_plus/src/model/media_channel.dart';
import 'package:flutter_cast_plus/src/model/queue_data.dart';
import 'package:flutter_cast_plus/src/model/queue_item.dart';
import 'package:flutter_cast_plus/src/model/receiver_channel.dart';
import 'package:flutter_cast_plus/src/model/track.dart';
import 'package:flutter_cast_plus/src/model/cast_media.dart';
import 'package:flutter_cast_plus/src/proto/cast_channel.pbserver.dart';
import 'dart:io';

import 'base_service.dart';

class ChromecastService extends BaseService {
  ChromecastService({required super.device});

  @override
  Future<bool> connect() async {
    logger.i('connect chromecast device: ${device.name}');

    connectionDidClose = false;

    castSession ??= CastSession(
        sourceId: 'client-${Random().nextInt(99999)}',
        destinationId: 'receiver-0');

    // connect to socket
    if (null == await createSocket()) {
      logger.e('Could not create socket');
      return false;
    }

    connectionChannel!.sendMessageChromecast({'type': 'CONNECT'}, requestId);
    requestId++;

    // start heartbeat
    heartbeatTick();

    return true;
  }

  @override
  Future<void> launch({String? appId}) async {
    logger.d('connectionChannel: $connectionChannel');

    if (connectionChannel != null) {
      final completer = Completer();
      queueRequests.add(CastCompleter(requestId, completer));
      receiverChannel!.sendMessageChromecast(
        {
          'type': 'LAUNCH',
          'appId': appId ?? 'CC1AD845',
        },
        requestId,
      );
      requestId++;
    }
  }

  @override
  Future<bool> reconnect({String? sourceId, String? destinationId}) async {
    castSession = CastSession(sourceId: sourceId, destinationId: destinationId);
    await connect();

    mediaChannel = MediaChannel.create(
        socket: socket, sourceId: sourceId, destinationId: destinationId);

    requestId++;
    final completer = Completer();
    queueRequests.add(CastCompleter(requestId, completer));
    mediaChannel!.sendMessageChromecast({'type': 'GET_STATUS'}, requestId);

    // now wait for the media to actually get a status?
    bool didReconnect = await _waitForMediaStatus();
    if (didReconnect) {
      // log.d('reconnecting successful!');
      try {
        castSessionController.add(castSession);
      } catch (e) {
        logger.e(
            "Could not add the CastSession to the CastSession Stream Controller: events will not be triggered");
        logger.e(e.toString());
        logger.i("Closed? ${castSessionController.isClosed}");
      }

      try {
        castMediaStatusController.add(castSession!.castMediaStatus);
      } catch (e) {
        logger.e(
            "Could not add the CastMediaStatus to the CastSession Stream Controller: events will not be triggered");
        logger.e(e.toString());
        logger.i("Closed? ${castMediaStatusController.isClosed}");
      }
    }
    return didReconnect;
  }

  @override
  Future<void> disconnect() async {
    requestId++;
    final completer = Completer();
    queueRequests.add(CastCompleter(requestId, completer));

    connectionChannel?.sendMessageChromecast(
      {
        'type': 'CLOSE',
      },
      requestId,
    );

    socket?.destroy();
    await dispose();
    connectionDidClose = true;
    return completer.future;
  }

  @override
  Future<void> dispose() async {
    logger.d('Disposing chromecast service');

    socket = null;
    heartbeatChannel = null;
    connectionChannel = null;
    receiverChannel = null;
    mediaChannel = null;
    castSession = null;
    queueData = null;
  }

  @override
  Future<SecureSocket?> createSocket() async {
    if (null == socket) {
      try {
        logger.i('Connecting to ${device.host}:${device.port}');

        socket = await SecureSocket.connect(
          device.host,
          device.port!,
          onBadCertificate: (X509Certificate certificate) => true,
          timeout: const Duration(seconds: 10),
        );

        connectionChannel = ConnectionChannel.create(
          socket,
          sourceId: castSession!.sourceId,
          destinationId: castSession!.destinationId,
          namespace: namespace,
        );
        heartbeatChannel = HeartbeatChannel.create(
          socket,
          sourceId: castSession!.sourceId,
          destinationId: castSession!.destinationId,
        );
        receiverChannel = ReceiverChannel.create(
          socket,
          sourceId: castSession!.sourceId,
          destinationId: castSession!.destinationId,
        );

        socket!.listen(onSocketData, onDone: dispose);
      } catch (e) {
        logger.e(e);
        return null;
      }
    }
    return socket;
  }

  @override
  Future<void> loadPlaylist(List<CastMedia> media,
      {append = false, forceNext = false}) async {
    if (null != mediaChannel) {
      await setActiveTracksIds([]);

      _convertCastMediasToQueue(media, append: append, forceNext: forceNext);
      if (queueData != null) {
        // dev.log('${queueData!.toJson()}');
        requestId++;
        final completer = Completer();
        queueRequests.add(CastCompleter(requestId, completer));
        mediaChannel!
            .sendMessageChromecast(queueData!.toChromecastJson(), requestId);
        return completer.future;
      }
    }
  }

  @override
  Future<void> pause() async {
    return await _castMediaAction('PAUSE');
  }

  @override
  Future<void> play() async {
    return await _castMediaAction('PLAY');
  }

  @override
  Future<void> next() async {
    await setActiveTracksIds([]);
    return await _castMediaAction('QUEUE_NEXT', {});
  }

  @override
  Future<void> previous() async {
    await setActiveTracksIds([]);
    return await _castMediaAction('QUEUE_PREV', {});
  }

  @override
  Future<void> seek(double time) async {
    Map<String, dynamic> map = {'currentTime': time};
    return await _castMediaAction('SEEK', map);
  }

  @override
  Future<void> stop() async {
    return await _castMediaAction('STOP');
  }

  @override
  Future<void> togglePause() async {
    if (true == castSession?.castMediaStatus?.isPlaying) {
      return await pause();
    } else if (true == castSession?.castMediaStatus?.isPaused) {
      return await play();
    }
  }

  @override
  Future<void> addTrack(Track track, int index) async {
    if (queueData != null) {
      // Reset current tracks
      setActiveTracksIds([]);
      final mediaIndex = getCurrentMediaIndex();

      for (var item in queueData!.items!) {
        item.itemId = null;
      }

      // log.v('Current Position: ${castSession?.castMediaStatus?.position}');

      queueData!.items?[mediaIndex].activeTrackIds = [track.trackId!];
      queueData!.items?[mediaIndex].media.tracks = [track];
      queueData!.currentTime = castSession?.castMediaStatus?.position;
      queueData!.startIndex = mediaIndex;

      requestId++;
      final completer = Completer();
      queueRequests.add(CastCompleter(requestId, completer));
      mediaChannel!
          .sendMessageChromecast(queueData!.toChromecastJson(), requestId);
      return completer.future;
    }
  }

  @override
  Future<void> setActiveTracksIds(List<int> trackIds) async {
    Map<String, dynamic> trackiMap = {
      "activeTrackIds": trackIds,
    };
    return await _castMediaAction('EDIT_TRACKS_i', trackiMap);
  }

  @override
  Future<void> setPlaybackRate(double rate) async {
    Map<String, dynamic> map = {
      "playbackRate": rate,
      "requestId": 1,
    };
    return await _castMediaAction('SET_PLAYBACK_RATE', map);
  }

  @override
  Future<void> setRepeatMode(String mode) async {
    Map<String, dynamic> map = {
      "repeatMode": mode,
    };

    return await _castMediaAction('QUEUE_UPDATE', map);
  }

  @override
  Future<void> setVolume(double volume) async {
    Map<String, dynamic> map = {
      'volume': {'level': volume, 'muted': false}
    };
    return await _castMediaAction('SET_VOLUME', map);
  }

  @override
  Future<void> mute() async {
    Map<String, dynamic> map = {
      'volume': {'muted': true}
    };
    return await _castMediaAction('SET_VOLUME', map);
  }

  @override
  Future<void> unmute() async {
    Map<String, dynamic> map = {
      'volume': {'muted': false}
    };
    return await _castMediaAction('SET_VOLUME', map);
  }

  @override
  void onSocketData(List<int> event) {
    // When receive this type try to reconnect session

    List<int> slice = event.getRange(4, event.length).toList();

    CastMessage message = CastMessage.fromBuffer(slice);
    // handle the message
    Map<String, dynamic> payloadMap = jsonDecode(message.payloadUtf8);

    if ('PING' != payloadMap['type'] && 'PONG' != payloadMap['type']) {
      if (kDebugMode) {
        logger.d('onSocket data: $payloadMap');
      }

      try {
        final castCompleter = queueRequests
            .where((element) => element.requestId == payloadMap['requestId'])
            .firstOrNull;
        // logger.i('completer id complete: ${castCompleter?.requestId}');
        castCompleter?.completer.complete();
        queueRequests.removeWhere(
            (element) => element.requestId == payloadMap['requestId']);
      } catch (e) {
        logger.e(e);
      }
    }

    if ('CLOSE' == payloadMap['type']) {
      dispose();
      connectionDidClose = true;
    }
    if ('RECEIVER_STATUS' == payloadMap['type']) {
      handleReceiverStatus(payloadMap);
    } else if ('MEDIA_STATUS' == payloadMap['type']) {
      handleMediaStatus(payloadMap);
    } else if ('CLOSE' == payloadMap['type']) {
      closeController.add(true);
    }
  }

  @override
  void handleReceiverStatus(Map payload) {
    // log.i("_handleReceiverStatus()");
    if (null == mediaChannel &&
        true == payload['status']?.containsKey('applications')) {
      // re-create the channel with the transportId the chromecast just sent us
      if (!castSession!.isConnected) {
        castSession = castSession!
          ..mergeWithChromeCastSessionMap(payload['status']['applications'][0]);
        connectionChannel = ConnectionChannel.create(
          socket,
          sourceId: castSession!.sourceId,
          destinationId: castSession!.destinationId,
          namespace: namespace,
        );
        requestId++;
        connectionChannel!
            .sendMessageChromecast({'type': 'CONNECT'}, requestId);
        mediaChannel = MediaChannel.create(
          socket: socket,
          sourceId: castSession!.sourceId,
          destinationId: castSession!.destinationId,
        );
        requestId++;
        mediaChannel!.sendMessageChromecast({'type': 'GET_STATUS'}, requestId);

        try {
          castSessionController.add(castSession);
        } catch (e) {
          logger.e(
              "Could not add the CastSession to the CastSession Stream Controller: events will not be triggered");
          logger.e(e.toString());
        }
      }
    }
  }

  @override
  void handleMediaStatus(Map payload) {
    if (payload['status'] != null) {
      if (castSession != null && !castSession!.isConnected) {
        castSession!.isConnected = true;
      }

      if (castSession != null && payload['status'].length > 0) {
        castSession!.castMediaStatus =
            CastMediaStatus.fromChromeCastMediaStatus(payload['status'][0]);

        if (payload['status'][0]['items'] != null && queueData != null) {
          for (var responseItem in payload['status'][0]['items']) {
            for (var item in queueData!.items!) {
              if (item.media.contentId == responseItem['media']['contentId']) {
                item.itemId = responseItem['itemId'];
              }
            }
          }
        }

        if (castSession!.castMediaStatus!.media != null) {
          currentMedia = castSession!.castMediaStatus!.media;
        }

        if (castSession!.castMediaStatus!.isFinished) {
          setActiveTracksIds([]);
        }

        if (castSession!.castMediaStatus!.isPlaying) {
          mediaCurrentTimeTimer =
              Timer(const Duration(seconds: 1), getMediaCurrentTime);
        } else if (castSession!.castMediaStatus!.isPaused &&
            null != mediaCurrentTimeTimer) {
          mediaCurrentTimeTimer!.cancel();
          mediaCurrentTimeTimer = null;
        }

        try {
          castMediaStatusController.add(castSession!.castMediaStatus);
        } catch (e) {
          logger.e(
              "Could not add the CastMediaStatus to the CastSession Stream Controller: events will not be triggered");
          logger.e(e.toString());
          logger.i("Closed? ${castMediaStatusController.isClosed}");
        }
      } else {
        logger.i("Media status is empty");
      }
    }
  }

  @override
  int getCurrentMediaIndex() {
    int result = 0;

    if (queueData != null && queueData!.items != null) {
      for (var i = 0; i < queueData!.items!.length; i++) {
        if (queueData!.items![i].media.title == currentMedia!.metadata.title) {
          result = i;
          break;
        }
      }
    }

    return result != 0 ? result - 1 : result;
  }

  @override
  void getMediaCurrentTime() {
    if (null != mediaChannel &&
        true == castSession?.castMediaStatus?.isPlaying) {
      requestId++;
      mediaChannel!.sendMessageChromecast(
        {
          'type': 'GET_STATUS',
        },
        requestId,
      );
    }
  }

  @override
  void heartbeatTick() {
    if (null != heartbeatChannel) {
      requestId++;
      heartbeatChannel!.sendMessageChromecast({'type': 'PING'}, requestId);
      Timer(const Duration(seconds: 5), heartbeatTick);
    }
  }

  Future<void> _castMediaAction(type, [params]) async {
    params ??= {};
    if (null != mediaChannel && null != castSession?.castMediaStatus) {
      dynamic message = params
        ..addAll({
          'mediaSessionId': castSession!.castMediaStatus!.sessionId,
          'type': type,
        });
      requestId++;
      final completer = Completer();
      queueRequests.add(CastCompleter(requestId, completer));
      mediaChannel!.sendMessageChromecast(message, requestId);
      return completer.future;
    }
  }

  void _convertCastMediasToQueue(List<CastMedia> media,
      {append = false, forceNext = false}) {
    List<QueueItem> queueItems = [];

    for (var i = 0; i < media.length; i++) {
      final element = media[i];

      final queueItem = QueueItem(
        media: element,
        orderId: i,
        preloadTime: 5,
        activeTrackIds: [],
      );

      queueItems.add(queueItem);
    }

    if (append && queueData != null) {
      queueData!.items?.addAll(queueItems);
    } else {
      queueData = QueueData(items: queueItems);
    }
  }

  Future<bool> _waitForMediaStatus() async {
    while (false == castSession!.isConnected) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (connectionDidClose) return false;
    }
    return castSession!.isConnected;
  }
}
