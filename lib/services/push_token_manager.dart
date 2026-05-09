import 'dart:io';
import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hello_flutter_app/services/auth_api_service.dart';
import 'package:hello_flutter_app/services/push_api_service.dart';
import 'package:hello_flutter_app/utils/app_navigator.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PushTokenManager {
  PushTokenManager({PushApiService? api, AuthApiService? authApi})
    : _api = api ?? PushApiService(),
      _authApi = authApi ?? AuthApiService();

  static const _sentTokenKey = 'push_fcm_token_sent';
  final PushApiService _api;
  final AuthApiService _authApi;

  Future<void> init() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await _ensurePermission();
    await _configureForegroundPresentation();
    _listenForegroundMessages();
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
    // Don't stall UI for too long; especially on iOS simulators APNs token may
    // not be available immediately (or at all), which can cause long waits.
    await _registerCurrentTokenIfNeeded(maxWaitSeconds: 6);
  }

  Future<void> _ensurePermission() async {
    await FirebaseMessaging.instance.requestPermission();
  }

  void _listenForegroundMessages() {
    FirebaseMessaging.onMessage.listen((message) async {
      final ctx = AppNavigator.context;
      if (ctx == null) return;
      if (!ctx.mounted) return;

      final title = message.notification?.title?.trim();
      final body = message.notification?.body?.trim();
      if ((title ?? '').isEmpty && (body ?? '').isEmpty) return;

      try {
        await showDialog<void>(
          context: ctx,
          builder: (context) {
            return AlertDialog(
              title: Text((title ?? '').isEmpty ? 'Yangi xabar' : title!),
              content: (body ?? '').isEmpty ? null : Text(body!),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      } on Object {
        // Ignore UI errors; foreground notifications are best-effort.
      }
    });
  }

  String _platformLabel() {
    if (Platform.isIOS) return 'ios';
    return 'android';
  }

  Future<void> _registerCurrentTokenIfNeeded({
    int attempt = 0,
    int maxWaitSeconds = 30,
    DateTime? startedAt,
  }) async {
    final started = startedAt ?? DateTime.now();
    String? token;
    try {
      if (Platform.isIOS) {
        final apns = await FirebaseMessaging.instance.getAPNSToken();
        if (apns == null || apns.trim().isEmpty) {
          token = null;
        } else {
          token = await FirebaseMessaging.instance.getToken();
        }
      } else {
        token = await FirebaseMessaging.instance.getToken();
      }
    } on FirebaseException catch (e) {
      if (e.code == 'apns-token-not-set') {
        token = null;
      } else {
        rethrow;
      }
    } on Exception {
      token = null;
    }

    if (token == null || token.trim().isEmpty) {
      if (Platform.isIOS &&
          attempt < 6 &&
          DateTime.now().difference(started).inSeconds < maxWaitSeconds) {
        final seconds = min(10, 1 + pow(2, attempt).toInt());
        await Future<void>.delayed(Duration(seconds: seconds));
        return _registerCurrentTokenIfNeeded(
          attempt: attempt + 1,
          maxWaitSeconds: maxWaitSeconds,
          startedAt: started,
        );
      }
      return;
    }

    await _registerTokenIfNeeded(token.trim());
  }

  Future<void> _registerTokenIfNeeded(String token) async {
    final session = await _authApi.loadSavedSession();
    if (session == null) return;

    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString(_sentTokenKey);
    final marker = '${session.phone}|$token';
    if (last == marker) return;
    final sent = await _api.registerDeviceToken(
      token: token,
      platform: _platformLabel(),
    );
    if (sent) {
      await prefs.setString(_sentTokenKey, marker);
    }
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}
