import 'package:flutter/foundation.dart';

class ApiConfig {
  // Host port the backend is published on. Must match the host side of the
  // backend `ports:` mapping in docker-compose.yml (5001:5000) - the container
  // still listens on 5000 internally, but nothing outside Docker reaches it
  // there. 5000 is unusable on macOS because AirPlay Receiver holds it.
  static const int apiPort = 5000;

  // Host the client dials. Android emulators reach the host machine through
  // the 10.0.2.2 loopback alias rather than localhost.
  static String get _host {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return '10.0.2.2';
    }
    return 'localhost';
  }

  static String get _origin => 'http://$_host:$apiPort';

  // Base URL calculation according to environment
  static String get baseUrl => '$_origin/api';

  // Base uploads URL
  static String get uploadsBaseUrl => '$_origin/uploads';
}
