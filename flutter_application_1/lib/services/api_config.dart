import 'package:flutter/foundation.dart';

class ApiConfig {
  // Base URL calculation according to environment
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // Android Emulator loopback
      return 'http://10.0.2.2:5000/api';
    } else {
      return 'http://localhost:5000/api';
    }
  }

  // Base uploads URL
  static String get uploadsBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/uploads';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000/uploads';
    } else {
      return 'http://localhost:5000/uploads';
    }
  }
}
