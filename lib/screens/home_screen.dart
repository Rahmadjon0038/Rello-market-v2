import 'package:flutter/material.dart';
import 'package:hello_flutter_app/widgets/home_header.dart';
import 'package:hello_flutter_app/widgets/home_bottom_bar.dart';
import 'package:hello_flutter_app/screens/favorites_screen.dart';
import 'package:hello_flutter_app/screens/cart_screen.dart';
import 'package:hello_flutter_app/screens/profile_screen.dart';
import 'package:hello_flutter_app/screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _lastNonProfileIndex = 0;

  void _setTab(int index) {
    setState(() {
      if (index != 3) _lastNonProfileIndex = index;
      _currentIndex = index;
    });
  }

  void _returnFromCancelledAuth() {
    if (!mounted) return;
    setState(() => _currentIndex = _lastNonProfileIndex);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const SizedBox.shrink(),
      FavoritesScreen(
        onGoHome: () {
          _setTab(0);
        },
      ),
      const CartScreen(),
      ProfileScreen(onAuthCancelled: _returnFromCancelledAuth),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: HomeBottomBar(
        currentIndex: _currentIndex,
        onTap: _setTab,
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            HomeHeader(
              showContent: _currentIndex == 0,
              showSearch: _currentIndex == 0,
            ),
            if (_currentIndex != 0) ...[
              const SizedBox(height: 16),
              pages[_currentIndex],
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}
