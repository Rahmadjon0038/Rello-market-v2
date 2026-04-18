import 'package:flutter/material.dart';

const List<String> allowedCategoryIconKeys = [
  'kitchen',
  'phone',
  'laptop',
  'clothes',
  'home',
  'beauty',
  'sport',
  'car',
  'book',
  'toy',
  'health',
  'grocery',
  'furniture',
  'tools',
  'gift',
  'appliances',
];

const Map<String, IconData> categoryIcons = {
  'kitchen': Icons.kitchen_rounded,
  'phone': Icons.phone_iphone_rounded,
  'laptop': Icons.laptop_mac_rounded,
  'clothes': Icons.checkroom_rounded,
  'home': Icons.home_rounded,
  'beauty': Icons.spa_rounded,
  'sport': Icons.sports_soccer_rounded,
  'car': Icons.directions_car_rounded,
  'book': Icons.menu_book_rounded,
  'toy': Icons.toys_rounded,
  'health': Icons.health_and_safety_rounded,
  'grocery': Icons.local_grocery_store_rounded,
  'furniture': Icons.chair_rounded,
  'tools': Icons.build_rounded,
  'gift': Icons.card_giftcard_rounded,
  'appliances': Icons.blender_rounded,
};

IconData categoryIconOf(String? key) {
  return categoryIcons[key] ?? Icons.category_rounded;
}
