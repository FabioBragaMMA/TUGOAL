import 'package:flutter/foundation.dart';

class ApiConfig {
   // conforme o sitio onde se encontre fazer ipconfig e colocar ip v4
  //static const String ipFisico = '192.168.1.72';
  static const String ipFisico = '172.16.64.101';
  static const String portaApi = '5177';

  static String get baseUrl {
    // Flutter Web / Chrome no PC
    if (kIsWeb) {
      return 'http://localhost:$portaApi/api';
    }

    // APK no telemóvel físico Android
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://$ipFisico:$portaApi/api';
    }
 
    // Windows / Desktop
    return 'http://localhost:$portaApi/api';
  }
}
