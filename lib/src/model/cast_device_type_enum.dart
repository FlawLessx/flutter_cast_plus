import 'package:flutter_cast_plus/src/utils/cast_tcp_constants.dart';

enum CastDeviceType {
  unknown,
  chromeCast,
  appleTV,
}

enum GoogleCastModelType {
  googleHub,
  googleHome,
  googleMini,
  googleMax,
  chromeCast,
  chromeCastAudio,
  nonGoogle,
  castGroup,
}

CastDeviceType defineCastDeviceType(String type) {
  if (type.contains(CastTCPConstants.chromecastTcp)) {
    return CastDeviceType.chromeCast;
  } else if (type.contains(CastTCPConstants.airplayTcp)) {
    return CastDeviceType.appleTV;
  }
  return CastDeviceType.unknown;
}

String castDeviceType2TCP(CastDeviceType type) {
  switch (type) {
    case CastDeviceType.chromeCast:
      return CastTCPConstants.chromecastTcp;
    case CastDeviceType.appleTV:
      return CastTCPConstants.airplayTcp;
    default:
      return '';
  }
}

GoogleCastModelType defineGoogleCastModelType(String modelName) {
  switch (modelName) {
    case "Google Home":
      return GoogleCastModelType.googleHome;
    case "Google Home Hub":
      return GoogleCastModelType.googleHub;
    case "Google Home Mini":
      return GoogleCastModelType.googleMini;
    case "Google Home Max":
      return GoogleCastModelType.googleMax;
    case "Chromecast":
      return GoogleCastModelType.chromeCast;
    case "Chromecast Audio":
      return GoogleCastModelType.chromeCastAudio;
    case "Google Cast Group":
      return GoogleCastModelType.castGroup;
    default:
      return GoogleCastModelType.nonGoogle;
  }
}
