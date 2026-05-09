import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hello_flutter_app/config/app_colors.dart';
import 'package:hello_flutter_app/config/api_config.dart';
import 'package:hello_flutter_app/services/push_token_manager.dart';
import 'package:hello_flutter_app/utils/app_navigator.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('API base URL: ${ApiConfig.baseUrl}');
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await PushTokenManager().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      home: const HomeScreen(), // boshlang‘ich oyna
    );
  }
}
