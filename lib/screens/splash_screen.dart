import 'package:flutter/material.dart';
import 'package:hello_flutter_app/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Keep a solid color behind the image to avoid visible bars while the image
  // is decoding and for extreme aspect ratios.
  static const _bg = Color(0xFF0B5A47);

  @override
  void initState() {
    super.initState();
    _goNext();
  }

  Future<void> _goNext() async {
    try {
      await precacheImage(const AssetImage('assets/splash.png'), context);
    } on Object {
      // best-effort
    }
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: _bg,
      body: SizedBox.expand(
        child: Image(image: AssetImage('assets/splash.png'), fit: BoxFit.cover),
      ),
    );
  }
}
