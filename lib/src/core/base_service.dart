import 'dart:async';
import 'dart:io';

import 'package:flutter_cast_plus/src/model/cast_completer.dart';
import 'package:flutter_cast_plus/src/model/cast_device.dart';
import 'package:flutter_cast_plus/src/model/cast_media.dart';
import 'package:flutter_cast_plus/src/model/cast_media_status.dart';
import 'package:flutter_cast_plus/src/model/cast_session.dart';
import 'package:flutter_cast_plus/src/model/connection_channel.dart';
import 'package:flutter_cast_plus/src/model/heartbeat_channel.dart';
import 'package:flutter_cast_plus/src/model/media_channel.dart';
import 'package:flutter_cast_plus/src/model/media_info.dart';
import 'package:flutter_cast_plus/src/model/queue_data.dart';
import 'package:flutter_cast_plus/src/model/receiver_channel.dart';
import 'package:flutter_cast_plus/src/model/track.dart';
import 'package:logger/logger.dart';

abstract class BaseService {
  BaseService({required this.device, this.namespace}) {
    castSessionController = StreamController.broadcast();
    castMediaStatusController = StreamController.broadcast();
    closeController = StreamController.broadcast();
  }

  final CastDevice device;
  final String? namespace;

  final logger = Logger();
  SecureSocket? socket;

  ConnectionChannel? connectionChannel;
  HeartbeatChannel? heartbeatChannel;
  ReceiverChannel? receiverChannel;
  MediaChannel? mediaChannel;

  late bool connectionDidClose;
  Timer? mediaCurrentTimeTimer;

  CastSession? castSession;
  late StreamController<CastSession?> castSessionController;
  late StreamController<CastMediaStatus?> castMediaStatusController;
  late StreamController<bool?> closeController;
  QueueData? queueData;
  MediaInfo? currentMedia;

  List<CastCompleter> queueRequests = [];
  int requestId = 1;

  Future<bool> connect();
  Future<void> launch();
  Future<void> reconnect({String? sourceId, String? destinationId});
  Future<void> disconnect();
  Future<void> loadPlaylist(List<CastMedia> media,
      {append = false, forceNext = false});
  Future<void> play();
  Future<void> pause();
  Future<void> togglePause();
  Future<void> stop();
  Future<void> seek(double time);
  Future<void> setVolume(double volume);
  Future<void> mute();
  Future<void> unmute();
  Future<void> setPlaybackRate(double rate);
  Future<void> next();
  Future<void> previous();
  Future<void> setRepeatMode(String mode);
  Future<void> addTrack(Track track, int index);
  Future<void> setActiveTracksIds(List<int> trackIds);
  int getCurrentMediaIndex();
  Future<SecureSocket?> createSocket();
  void onSocketData(List<int> event);
  void handleReceiverStatus(Map payload);
  void handleMediaStatus(Map payload);
  void getMediaCurrentTime();
  void heartbeatTick();
  Future<void> dispose();
}
