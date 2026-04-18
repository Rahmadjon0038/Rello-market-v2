import 'package:flutter/material.dart';
import 'package:hello_flutter_app/widgets/home_header.dart';
import 'package:hello_flutter_app/widgets/home_bottom_bar.dart';
import 'package:hello_flutter_app/screens/favorites_screen.dart';
import 'package:hello_flutter_app/screens/cart_screen.dart';
import 'package:hello_flutter_app/screens/profile_screen.dart';
import 'package:hello_flutter_app/screens/settings_screen.dart';
import 'package:hello_flutter_app/services/auth_api_service.dart';
import 'package:hello_flutter_app/services/product_api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductApiService _productApi = ProductApiService();
  int _currentIndex = 0;
  int _lastNonProfileIndex = 0;
  ProductSummary _summary = const ProductSummary.empty();

  @override
  void initState() {
    super.initState();
    _refreshSummary();
  }

  Future<void> _refreshSummary() async {
    try {
      final summary = await _productApi.getProductSummary();
      if (!mounted) return;
      setState(() => _summary = summary);
    } on AuthApiException {
      if (!mounted) return;
      setState(() => _summary = const ProductSummary.empty());
    } on Object {
      // Keep the last visible count when the network is temporarily unavailable.
    }
  }

  void _setTab(int index) {
    setState(() {
      if (index != 3) _lastNonProfileIndex = index;
      _currentIndex = index;
    });
    _refreshSummary();
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
        onSummaryChanged: _refreshSummary,
      ),
      CartScreen(onSummaryChanged: _refreshSummary),
      ProfileScreen(
        onAuthCancelled: _returnFromCancelledAuth,
        onAuthChanged: _refreshSummary,
      ),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: HomeBottomBar(
        currentIndex: _currentIndex,
        favoriteCount: _summary.favoriteCount,
        cartCount: _summary.cartTotalQty,
        onTap: _setTab,
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            HomeHeader(
              showContent: _currentIndex == 0,
              showSearch: _currentIndex == 0,
              onSummaryChanged: _refreshSummary,
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
