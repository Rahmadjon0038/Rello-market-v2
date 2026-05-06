import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hello_flutter_app/services/push_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PushTokenManager {
  PushTokenManager({PushApiService? api}) : _api = api ?? PushApiService();

  static const _sentTokenKey = 'push_fcm_token_sent';
  final PushApiService _api;

  Future<void> init() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await _ensurePermission();
    await _configureForegroundPresentation();
    await registerNow();
    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      await _registerTokenIfNeeded(token);
    });
  }

  Future<void> _configureForegroundPresentation() async {
    if (!Platform.isIOS) return;
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  Future<void> registerNow() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await _registerCurrentTokenIfNeeded();
  }

  Future<void> _ensurePermission() async {
    await FirebaseMessaging.instance.requestPermission();
  }

  String _platformLabel() {
    if (Platform.isIOS) return 'ios';
    return 'android';
  }

  Future<void> _registerCurrentTokenIfNeeded() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.trim().isEmpty) return;
    await _registerTokenIfNeeded(token.trim());
  }

  Future<void> _registerTokenIfNeeded(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString(_sentTokenKey);
    if (last == token) return;
    final sent = await _api.registerDeviceToken(
      token: token,
      platform: _platformLabel(),
    );
    if (sent) {
      await prefs.setString(_sentTokenKey, token);
    }
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}
