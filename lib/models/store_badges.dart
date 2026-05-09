class StoreBadges {
  final int orders;

  const StoreBadges({required this.orders});

  const StoreBadges.empty() : orders = 0;

  factory StoreBadges.fromJson(Object? json) {
    if (json is Map<String, dynamic>) {
      return StoreBadges(orders: _intFromJson(json['orders']));
    }
    return const StoreBadges.empty();
  }

  bool get hasAny => orders > 0;

  static int _intFromJson(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
