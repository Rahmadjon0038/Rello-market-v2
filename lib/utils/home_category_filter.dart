import 'package:flutter/foundation.dart';

class HomeCategoryFilter {
  HomeCategoryFilter._();

  static final ValueNotifier<String?> selectedCategoryId =
      ValueNotifier<String?>(null);

  static void setCategory(String? categoryId) {
    final normalized = categoryId?.trim();
    if (normalized == selectedCategoryId.value) return;
    selectedCategoryId.value = normalized;
  }
}
