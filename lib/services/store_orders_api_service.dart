import 'dart:convert';
import 'dart:io';

import 'package:hello_flutter_app/config/api_config.dart';
import 'package:hello_flutter_app/models/order.dart';
import 'package:hello_flutter_app/services/auth_api_service.dart';

class StoreOrdersApiService {
  StoreOrdersApiService({HttpClient? client, AuthApiService? authApi})
    : _client = client ?? HttpClient(),
      _authApi = authApi ?? AuthApiService();

  final HttpClient _client;
  final AuthApiService _authApi;

  Future<StoreOrdersStats> getStoreOrdersStats(
    String storeId, {
    String period = 'all',
    String? month,
    String? from,
    String? to,
    String? status,
    String? categoryId,
    String tz = 'Asia/Tashkent',
  }) async {
    final query = <String, String>{'period': period, 'tz': tz};
    if ((month ?? '').trim().isNotEmpty) query['month'] = month!.trim();
    if ((from ?? '').trim().isNotEmpty) query['from'] = from!.trim();
    if ((to ?? '').trim().isNotEmpty) query['to'] = to!.trim();
    if ((status ?? '').trim().isNotEmpty) query['status'] = status!.trim();
    if ((categoryId ?? '').trim().isNotEmpty) {
      query['categoryId'] = categoryId!.trim();
    }
    final qp = query.entries
        .map(
          (e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
        )
        .join('&');
    final data = await _send(
      'GET',
      '/me/stores/$storeId/orders/stats?$qp',
      authRequired: true,
    );
    final raw = data['data'];
    if (raw is Map<String, dynamic>) return StoreOrdersStats.fromJson(raw);
    return const StoreOrdersStats.empty();
  }

  Future<List<OrderModel>> getStoreOrders(
    String storeId, {
    String? status,
  }) async {
    final query = (status == null || status.trim().isEmpty)
        ? ''
        : '?status=${Uri.encodeQueryComponent(status.trim())}';
    final data = await _send(
      'GET',
      '/me/stores/$storeId/orders$query',
      authRequired: true,
    );
    final raw =
        data['data'] ??
        data['orders'] ??
        data['items'] ??
        (data['order'] is List ? data['order'] : null);
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(OrderModel.fromJson)
        .toList();
  }

  Future<OrderModel> getStoreOrder(String storeId, String orderId) async {
    final data = await _send(
      'GET',
      '/me/stores/$storeId/orders/$orderId',
      authRequired: true,
    );
    final rawOrder = data['order'];
    if (rawOrder is Map<String, dynamic>) return OrderModel.fromJson(rawOrder);
    return OrderModel.fromJson(data);
  }

  Future<OrderModel> acceptOrder({
    required String storeId,
    required String orderId,
  }) async {
    final data = await _send(
      'PATCH',
      '/me/stores/$storeId/orders/$orderId/accept',
      authRequired: true,
      body: {},
    );
    final rawOrder = data['order'];
    if (rawOrder is Map<String, dynamic>) return OrderModel.fromJson(rawOrder);
    return OrderModel.fromJson(data);
  }

  Future<OrderModel> rejectOrder({
    required String storeId,
    required String orderId,
  }) async {
    final data = await _send(
      'PATCH',
      '/me/stores/$storeId/orders/$orderId/reject',
      authRequired: true,
      body: {},
    );
    final rawOrder = data['order'];
    if (rawOrder is Map<String, dynamic>) return OrderModel.fromJson(rawOrder);
    return OrderModel.fromJson(data);
  }

  Future<OrderModel> markDelivered({
    required String storeId,
    required String orderId,
    required String code,
  }) async {
    final data = await _send(
      'PATCH',
      '/me/stores/$storeId/orders/$orderId/delivered',
      authRequired: true,
      body: {'code': code},
    );
    final rawOrder = data['order'];
    if (rawOrder is Map<String, dynamic>) return OrderModel.fromJson(rawOrder);
    return OrderModel.fromJson(data);
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    bool authRequired = false,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final request = await _client.openUrl(method, uri);
    request.headers.contentType = ContentType.json;

    final session = await _authApi.loadSavedSession();
    if (session != null) {
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer ${session.accessToken}',
      );
    } else if (authRequired) {
      throw const AuthApiException('Avval tizimga kiring');
    }

    if (body != null) request.write(jsonEncode(body));

    final response = await request.close();
    final rawBody = await response.transform(utf8.decoder).join();
    final decoded = _decodeJson(rawBody);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final exception = AuthApiException(
        decoded['error']?.toString() ??
            decoded['message']?.toString() ??
            'Server xatosi',
        statusCode: response.statusCode,
      );
      if (AuthApiService.isInvalidSessionError(exception)) {
        await _authApi.clearSession();
      }
      throw exception;
    }

    return decoded;
  }

  Map<String, dynamic> _decodeJson(String rawBody) {
    if (rawBody.trim().isEmpty) return <String, dynamic>{};
    Object decoded;
    try {
      decoded = jsonDecode(rawBody);
    } on FormatException {
      final sample = rawBody.trim().replaceAll(RegExp(r'\s+'), ' ');
      final preview = sample.length > 180 ? sample.substring(0, 180) : sample;
      throw AuthApiException(
        "Server javobi JSON emas. Javob: ${preview.isEmpty ? '-' : preview}",
      );
    }
    if (decoded is Map<String, dynamic>) return decoded;
    throw const AuthApiException("Server javobi noto'g'ri formatda");
  }
}

class StoreOrdersStatsByCategory {
  final String? categoryId;
  final String? categoryName;
  final int qty;
  final int sum;

  const StoreOrdersStatsByCategory({
    required this.categoryId,
    required this.categoryName,
    required this.qty,
    required this.sum,
  });

  factory StoreOrdersStatsByCategory.fromJson(Map<String, dynamic> json) {
    return StoreOrdersStatsByCategory(
      categoryId: json['categoryId']?.toString(),
      categoryName: json['categoryName']?.toString(),
      qty: _intFromJson(json['qty']),
      sum: _intFromJson(json['sum']),
    );
  }
}

class StoreOrdersStatsByStatus {
  final int pending;
  final int delivering;
  final int rejected;
  final int delivered;

  const StoreOrdersStatsByStatus({
    required this.pending,
    required this.delivering,
    required this.rejected,
    required this.delivered,
  });

  const StoreOrdersStatsByStatus.empty()
    : pending = 0,
      delivering = 0,
      rejected = 0,
      delivered = 0;

  factory StoreOrdersStatsByStatus.fromJson(Map<String, dynamic> json) {
    return StoreOrdersStatsByStatus(
      pending: _intFromJson(json['pending']),
      delivering: _intFromJson(json['delivering']),
      rejected: _intFromJson(json['rejected']),
      delivered: _intFromJson(json['delivered']),
    );
  }
}

class StoreOrdersStats {
  final int ordersCount;
  final int totalSum;
  final int deliveredSum;
  final int itemsQty;
  final int itemsSum;
  final StoreOrdersStatsByStatus byStatus;
  final List<StoreOrdersStatsByCategory> byCategory;

  const StoreOrdersStats({
    required this.ordersCount,
    required this.totalSum,
    required this.deliveredSum,
    required this.itemsQty,
    required this.itemsSum,
    required this.byStatus,
    required this.byCategory,
  });

  const StoreOrdersStats.empty()
    : ordersCount = 0,
      totalSum = 0,
      deliveredSum = 0,
      itemsQty = 0,
      itemsSum = 0,
      byStatus = const StoreOrdersStatsByStatus.empty(),
      byCategory = const [];

  factory StoreOrdersStats.fromJson(Map<String, dynamic> json) {
    final rawByStatus = json['byStatus'];
    final rawByCategory = json['byCategory'];
    return StoreOrdersStats(
      ordersCount: _intFromJson(json['ordersCount']),
      totalSum: _intFromJson(json['totalSum']),
      deliveredSum: _intFromJson(json['deliveredSum']),
      itemsQty: _intFromJson(json['itemsQty']),
      itemsSum: _intFromJson(json['itemsSum']),
      byStatus: rawByStatus is Map<String, dynamic>
          ? StoreOrdersStatsByStatus.fromJson(rawByStatus)
          : const StoreOrdersStatsByStatus.empty(),
      byCategory: rawByCategory is List
          ? rawByCategory
                .whereType<Map<String, dynamic>>()
                .map(StoreOrdersStatsByCategory.fromJson)
                .toList()
          : const [],
    );
  }
}

int _intFromJson(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
