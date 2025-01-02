import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_cast_plus/src/core/base_service.dart';
import 'package:flutter_cast_plus/src/core/chromecast_service.dart';
import 'package:flutter_cast_plus/src/model/cast_device_type_enum.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:logger/logger.dart';

class CastDevice {
  final logger = Logger();

  final String? name;
  final String? type;
  final String? host;
  final int? port;

  /// Contains the information about the device.
  /// You can decode with utf8 a bunch of information
  ///
  /// * md - Model Name (e.g. "Chromecast");
  /// * id - UUID without hyphens of the particular device (e.g. xx12x3x456xx789xx01xx234x56789x0);
  /// * fn - Friendly Name of the device (e.g. "Living Room");
  /// * rs - Unknown (recent share???) (e.g. "Youtube TV");
  /// * bs - Unknown (e.g. "XX1XXX2X3456");
  /// * st - Unknown (e.g. "1");
  /// * ca - Unknown (e.g. "1234");
  /// * ic - Icon path (e.g. "/setup/icon.png");
  /// * ve - Version (e.g. "04").
  final Map<String, Uint8List?>? attr;

  String? _friendlyName;
  String? _modelName;

  CastDevice({
    this.name,
    this.type,
    this.host,
    this.port,
    this.attr,
  });
  // {
  //   initDeviceInfo();
  // }

  Future<void> initDeviceInfo() async {
    deviceType = defineCastDeviceType(type ?? '');

    if (deviceType == CastDeviceType.chromeCast) {
      service = ChromecastService(device: this);
    }
    //  else if (deviceType ==  CastDeviceType.appleTV){
    //    service = ChromecastService(device: this);
    // }

    if (CastDeviceType.chromeCast == deviceType) {
      googleModelType = defineGoogleCastModelType(modelName ?? '');
      await _initChromecast();
    }
  }

  Future<void> _initChromecast() async {
    if (attr != null) {
      logger.i(attr);
    }

    if (null != attr && null != attr!['fn']) {
      _friendlyName = utf8.decode(attr!['fn']!);
      if (null != attr!['md']) {
        _modelName = utf8.decode(attr!['md']!);
      }
    } else {
      // Attributes are not guaranteed to be set, if not set fetch them via the eureka_info url
      // Possible parameters: version,audio,name,build_info,detail,device_info,net,wifi,setup,settings,opt_in,opencast,multizone,proxy,night_mode_params,user_eq,room_equalizer
      try {
        bool trustSelfSigned = true;
        HttpClient httpClient = HttpClient()
          ..badCertificateCallback =
              ((X509Certificate cert, String host, int port) =>
                  trustSelfSigned);
        IOClient ioClient = IOClient(httpClient);
        final uri = Uri.parse(
            'https://$host:8443/setup/eureka_info?params=name,device_info');
        http.Response response = await ioClient.get(uri);
        Map deviceInfo = jsonDecode(response.body);
        logger.i(deviceInfo);

        if (deviceInfo['name'] != null && deviceInfo['name'] != 'Unknown') {
          _friendlyName = deviceInfo['name'];
        } else if (deviceInfo['ssid'] != null) {
          _friendlyName = deviceInfo['ssid'];
        }

        if (deviceInfo['model_name'] != null) {
          _modelName = deviceInfo['model_name'];
        }
      } catch (exception) {
        logger.e(exception);
      }
    }
  }

  late CastDeviceType deviceType;

  String? get friendlyName => _friendlyName ?? name;

  String? get modelName => _modelName;

  late GoogleCastModelType googleModelType;

  late BaseService service;
}
