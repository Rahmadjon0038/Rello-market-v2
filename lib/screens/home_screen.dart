import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hello_flutter_app/widgets/home_header.dart';
import 'package:hello_flutter_app/widgets/home_bottom_bar.dart';
import 'package:hello_flutter_app/screens/favorites_screen.dart';
import 'package:hello_flutter_app/screens/cart_screen.dart';
import 'package:hello_flutter_app/screens/profile_screen.dart';
import 'package:hello_flutter_app/screens/settings_screen.dart';
import 'package:hello_flutter_app/services/auth_api_service.dart';
import 'package:hello_flutter_app/services/product_api_service.dart';
import 'package:hello_flutter_app/services/store_api_service.dart';
import 'package:hello_flutter_app/utils/home_category_filter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductApiService _productApi = ProductApiService();
  final StoreApiService _storeApi = StoreApiService();
  int _currentIndex = 0;
  int _lastNonProfileIndex = 0;
  ProductSummary _summary = const ProductSummary.empty();
  int _sellerOrdersBadge = 0;

  @override
  void initState() {
    super.initState();
    _refreshSummary();
  }

  Future<void> _refreshSellerBadge() async {
    try {
      final session = await AuthApiService().loadSavedSession();
      final role = (session?.role ?? '').trim().toLowerCase();
      if (role != 'seller') {
        if (!mounted) return;
        if (_sellerOrdersBadge != 0) setState(() => _sellerOrdersBadge = 0);
        return;
      }
      final count = await _storeApi.getMyStoresOrdersBadge();
      if (!mounted) return;
      setState(() => _sellerOrdersBadge = count);
    } on Object {
      // best-effort
    }
  }

  Future<void> _refreshSummary() async {
    try {
      final summary = await _productApi.getProductSummary();
      if (!mounted) return;
      setState(() => _summary = summary);
      unawaited(_refreshSellerBadge());
    } on AuthApiException {
      if (!mounted) return;
      setState(() => _summary = const ProductSummary.empty());
      unawaited(_refreshSellerBadge());
    } on Object {
      // Keep the last visible count when the network is temporarily unavailable.
      unawaited(_refreshSellerBadge());
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
      CartScreen(
        onSummaryChanged: _refreshSummary,
        onGoHomeToCategory: (categoryId) {
          HomeCategoryFilter.setCategory(categoryId);
          _setTab(0);
        },
      ),
      ProfileScreen(
        onAuthCancelled: _returnFromCancelledAuth,
        onAuthChanged: _refreshSummary,
        onSellerOrdersBadgeChanged: (count) {
          if (!mounted) return;
          if (_sellerOrdersBadge == count) return;
          setState(() => _sellerOrdersBadge = count);
        },
      ),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar: HomeBottomBar(
        currentIndex: _currentIndex,
        favoriteCount: _summary.favoriteCount,
        cartCount: _summary.cartTotalQty,
        profileBadgeCount: _sellerOrdersBadge,
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
