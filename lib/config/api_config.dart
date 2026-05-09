import 'package:flutter/foundation.dart';

class ApiConfig {
  // Preferred override (all platforms):
  //   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000
  //   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
  static const String _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');

  // Optional switch (when API_BASE_URL is not provided):
  //   flutter run --dart-define=API_TARGET=android_emulator
  //   flutter run --dart-define=API_TARGET=ios_simulator
  //   flutter run --dart-define=API_TARGET=device --dart-define=API_DEVICE_HOST=192.168.1.10
  static const String _apiTarget = String.fromEnvironment('API_TARGET');
  static const String _deviceHost = String.fromEnvironment('API_DEVICE_HOST');
  static const String _devicePort =
      String.fromEnvironment('API_DEVICE_PORT', defaultValue: '3000');

  // Production API (real backend).
  static const String _prodBaseUrl =
      'https://rello-market.taraqqiyot-teaching-center.uz';

  // Local backend (simulator/emulator options).
  // Android emulator -> localhost on your computer:
  static const String _androidEmulatorBaseUrl = 'http://10.0.2.2:3000';

  // iOS simulator -> localhost on your computer:
  static const String _iosSimulatorBaseUrl = 'http://localhost:3000';

  // Real device (example; must be your computer's LAN IP):
  // static const String _deviceExampleBaseUrl = 'http://192.168.1.10:3000';

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      if (kDebugMode) {
        debugPrint(
          'ApiConfig: using API_BASE_URL from --dart-define: $_configuredBaseUrl',
        );
      }
      return _configuredBaseUrl;
    }

    if (_apiTarget.trim().isNotEmpty) {
      final target = _apiTarget.trim().toLowerCase();
      switch (target) {
        case 'prod':
        case 'production':
          return _prodBaseUrl;
        case 'android_emulator':
        case 'emulator':
          return _androidEmulatorBaseUrl;
        case 'ios_simulator':
        case 'simulator':
          return _iosSimulatorBaseUrl;
        case 'device':
        case 'phone':
          if (_deviceHost.trim().isNotEmpty) {
            return 'http://${_deviceHost.trim()}:${_devicePort.trim()}';
          }
          if (kDebugMode) {
            debugPrint(
              'ApiConfig: API_TARGET=device set, but API_DEVICE_HOST is empty; falling back to prod',
            );
          }
          return _prodBaseUrl;
        default:
          if (kDebugMode) {
            debugPrint('ApiConfig: unknown API_TARGET=$target; using prod');
          }
          return _prodBaseUrl;
      }
    }

    // In release builds, default to production.
    if (kReleaseMode) {
      if (kDebugMode) {
        debugPrint('ApiConfig: kReleaseMode=true, baseUrl=$_prodBaseUrl');
      }
      return _prodBaseUrl;
    }

    // Debug default:
    // - Android: default to emulator loopback for local backend.
    // - iOS simulator: default to localhost for local backend.
    // - Real iOS/Android devices: pass API_BASE_URL or API_TARGET=device + API_DEVICE_HOST.
    final platform = defaultTargetPlatform;
    final debugDefault = switch (platform) {
      TargetPlatform.android => _androidEmulatorBaseUrl,
      TargetPlatform.iOS => _iosSimulatorBaseUrl,
      _ => _prodBaseUrl,
    };
    if (kDebugMode) {
      debugPrint('ApiConfig: debug default baseUrl=$debugDefault');
    }
    return debugDefault;
  }
}
