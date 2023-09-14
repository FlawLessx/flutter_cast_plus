import 'media_info.dart';

class CastMediaStatus {
  final dynamic _sessionId;

  final String? _nativeStatus;
  final bool _isPlaying;
  final bool _isPaused;
  final bool _isMuted;
  final bool _isIdle;
  final bool _isFinished;
  final bool _isCancelled;
  final bool _hasError;
  final bool _isLoading;
  final bool _isBuffering;
  final double? _volume;
  final double? _position;
  final int? _currentItemId;
  final MediaInfo? _mediaInfo;

  CastMediaStatus.fromChromeCastMediaStatus(Map mediaStatus)
      : _sessionId = mediaStatus['mediaSessionId'],
        _nativeStatus = mediaStatus['playerState'],
        _currentItemId = mediaStatus['currentItemId'],
        _isIdle = 'IDLE' == mediaStatus['playerState'],
        _isPlaying = 'PLAYING' == mediaStatus['playerState'],
        _isPaused = 'PAUSED' == mediaStatus['playerState'],
        _isMuted = null != mediaStatus['volume'] &&
            true == mediaStatus['volume']['muted'],
        _isLoading = 'LOADING' == mediaStatus['playerState'],
        _isBuffering = 'BUFFERING' == mediaStatus['playerState'],
        _isFinished = 'IDLE' == mediaStatus['playerState'] &&
            'FINISHED' == mediaStatus['idleReason'],
        _isCancelled = 'IDLE' == mediaStatus['playerState'] &&
            'CANCELLED' == mediaStatus['idleReason'],
        _hasError = 'IDLE' == mediaStatus['playerState'] &&
            'ERROR' == mediaStatus['idleReason'],
        _volume = null != mediaStatus['volume']
            ? mediaStatus['volume']['level'].toDouble()
            : null,
        _position = mediaStatus['currentTime'].toDouble(),
        _mediaInfo = mediaStatus['extendedStatus'] != null
            ? MediaInfo.fromChromecastJson(
                mediaStatus['extendedStatus']['media'])
            : null;

  dynamic get sessionId => _sessionId;

  String? get nativeStatus => _nativeStatus;

  int? get currentItemId => _currentItemId;

  bool get isIdle => _isIdle;

  bool get isPlaying => _isPlaying;

  bool get isFinished => _isFinished;

  bool get isCancelled => _isCancelled;

  bool get isPaused => _isPaused;

  bool get isMuted => _isMuted;

  bool get isLoading => _isLoading;

  bool get isBuffering => _isBuffering;

  bool get hasError => _hasError;

  double? get volume => _volume;

  double? get position => _position;

  MediaInfo? get media => _mediaInfo;
}
