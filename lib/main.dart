import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hello_flutter_app/config/app_colors.dart';
import 'package:hello_flutter_app/config/api_config.dart';
import 'package:hello_flutter_app/services/push_token_manager.dart';
import 'package:hello_flutter_app/utils/app_navigator.dart';
import 'package:hello_flutter_app/screens/splash_screen.dart';

Future<void> main() async {
  _installGlobalErrorHandlers();

  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      debugPrint('API base URL: ${ApiConfig.baseUrl}');
      final firebaseReady = await _tryInitFirebase();
      if (firebaseReady) {
        FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler,
        );
      }
      runApp(MyApp(firebaseReady: firebaseReady));
    },
    (error, stack) {
      debugPrint('Uncaught zone error: $error');
      debugPrintStack(stackTrace: stack);
      runApp(_InitFailedApp(error: error, stackTrace: stack));
    },
  );
}

void _installGlobalErrorHandlers() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exception}');
    if (details.stack != null) {
      debugPrintStack(stackTrace: details.stack);
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('PlatformDispatcher error: $error');
    debugPrintStack(stackTrace: stack);
    return false;
  };
}

Future<bool> _tryInitFirebase() async {
  try {
    await Firebase.initializeApp();
    return true;
  } on Object catch (e, st) {
    debugPrint('Firebase.initializeApp failed: $e');
    debugPrintStack(stackTrace: st);
    return false;
  }
}

Future<void> _tryInitPushMessaging() async {
  try {
    await PushTokenManager().init();
  } on Object catch (e, st) {
    // Push notifications are best-effort; don't block app startup.
    debugPrint('PushTokenManager.init failed: $e');
    debugPrintStack(stackTrace: st);
  }
}

class MyApp extends StatefulWidget {
  final bool firebaseReady;

  const MyApp({super.key, required this.firebaseReady});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    if (widget.firebaseReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tryInitPushMessaging();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // debug yozuvni olib tashlaydi
      navigatorKey: AppNavigator.key,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.appBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryGreen,
          primary: AppColors.primaryGreen,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
        ),
      ),
      home: const SplashScreen(), // boshlang‘ich oyna
    );
  }
}

class _InitFailedApp extends StatelessWidget {
  final Object error;
  final StackTrace? stackTrace;

  const _InitFailedApp({required this.error, this.stackTrace});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF6F7F8),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const Text(
                  'Ilova ochilmadi',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Boshlanishda xatolik yuz berdi. Konsol logini tekshiring.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE4E7EA)),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        '$error\n\n${stackTrace ?? ''}'.trim(),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          height: 1.35,
                          color: Color(0xFF2B2E31),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
