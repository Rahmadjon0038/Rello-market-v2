import 'package:hello_flutter_app/config/api_config.dart';

class OrderItemModel {
  final String id;
  final String productId;
  final String productName;
  final String productImage;
  final int unitPrice;
  final int qty;
  final int lineTotal;
  final int sortOrder;

  const OrderItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.unitPrice,
    required this.qty,
    required this.lineTotal,
    required this.sortOrder,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      productImage: resolveImagePath(json['productImage']?.toString() ?? ''),
      unitPrice: _intFromJson(json['unitPrice']),
      qty: _intFromJson(json['qty'], fallback: 1),
      lineTotal: _intFromJson(json['lineTotal']),
      sortOrder: _intFromJson(json['sortOrder']),
    );
  }

  static int _intFromJson(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static String resolveImagePath(String path) {
    if (path.trim().isEmpty) return '';
    if (path.startsWith('assets/')) return path;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    if (!path.startsWith('/')) return '${ApiConfig.baseUrl}/$path';
    return '${ApiConfig.baseUrl}$path';
  }
}

class OrderReceiverModel {
  final String firstName;
  final String lastName;
  final String phone;

  const OrderReceiverModel({
    required this.firstName,
    required this.lastName,
    required this.phone,
  });

  factory OrderReceiverModel.fromJson(Map<String, dynamic> json) {
    return OrderReceiverModel(
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
    );
  }

  String get fullName {
    final parts = [
      firstName.trim(),
      lastName.trim(),
    ].where((e) => e.isNotEmpty).toList();
    return parts.isEmpty ? '' : parts.join(' ');
  }
}

class OrderDeliveryModel {
  final String addressText;
  final double? lat;
  final double? lng;

  const OrderDeliveryModel({
    required this.addressText,
    required this.lat,
    required this.lng,
  });

  factory OrderDeliveryModel.fromJson(Map<String, dynamic> json) {
    final lat = _doubleFromJson(json['lat']);
    final lng = _doubleFromJson(json['lng']);
    return OrderDeliveryModel(
      addressText: json['addressText']?.toString() ?? '',
      lat: lat,
      lng: lng,
    );
  }

  static double? _doubleFromJson(Object? value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}

class OrderModel {
  final String id;
  final String userId;
  final String storeId;
  final String status;
  final String paymentMethod;
  final int total;
  final String currency;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final OrderReceiverModel? receiver;
  final OrderDeliveryModel? delivery;
  final List<OrderItemModel> items;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.storeId,
    required this.status,
    required this.paymentMethod,
    required this.total,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
    required this.receiver,
    required this.delivery,
    required this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(OrderItemModel.fromJson)
              .toList()
        : <OrderItemModel>[];
    items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final rawReceiver = json['receiver'];
    final receiver = rawReceiver is Map<String, dynamic>
        ? OrderReceiverModel.fromJson(rawReceiver)
        : null;

    final rawDelivery = json['delivery'];
    final delivery = rawDelivery is Map<String, dynamic>
        ? OrderDeliveryModel.fromJson(rawDelivery)
        : null;

    return OrderModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      storeId: json['storeId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      paymentMethod: json['paymentMethod']?.toString() ?? '',
      total: OrderItemModel._intFromJson(json['total']),
      currency: json['currency']?.toString() ?? 'UZS',
      createdAt: _dateFromJson(json['createdAt']),
      updatedAt: _dateFromJson(json['updatedAt']),
      receiver: receiver,
      delivery: delivery,
      items: items,
    );
  }

  static DateTime? _dateFromJson(Object? value) {
    if (value == null) return null;
    final s = value.toString().trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }
}
