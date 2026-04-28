import 'dart:convert';
import 'dart:io';

import 'package:hello_flutter_app/config/api_config.dart';
import 'package:hello_flutter_app/models/order.dart';
import 'package:hello_flutter_app/services/auth_api_service.dart';

class OrderApiService {
  OrderApiService({HttpClient? client, AuthApiService? authApi})
    : _client = client ?? HttpClient(),
      _authApi = authApi ?? AuthApiService();

  final HttpClient _client;
  final AuthApiService _authApi;

  Future<OrderModel> createOrder({
    String? storeId,
    required Map<String, dynamic> receiver,
    required Map<String, dynamic> delivery,
    required String paymentMethod,
  }) async {
    final data = await _send(
      'POST',
      '/orders',
      authRequired: true,
      body: {
        if ((storeId ?? '').trim().isNotEmpty) 'storeId': storeId!.trim(),
        'receiver': receiver,
        'delivery': delivery,
        'paymentMethod': paymentMethod,
      },
    );
    return OrderModel.fromJson(data);
  }

  Future<List<OrderModel>> getMyOrders() async {
    final data = await _send('GET', '/orders', authRequired: true);
    final raw = data['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(OrderModel.fromJson)
        .toList();
  }

  Future<OrderModel> getOrder(String id) async {
    final data = await _send('GET', '/orders/$id', authRequired: true);
    return OrderModel.fromJson(data);
  }

  Future<OrderDeliveryConfirmModel> getOrderDeliveryConfirm(String id) async {
    final data = await _send(
      'GET',
      '/orders/$id/delivery-confirm',
      authRequired: true,
    );
    return OrderDeliveryConfirmModel.fromJson(data);
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

class OrderDeliveryConfirmModel {
  final String orderId;
  final String code;
  final String qrPayload;

  const OrderDeliveryConfirmModel({
    required this.orderId,
    required this.code,
    required this.qrPayload,
  });

  factory OrderDeliveryConfirmModel.fromJson(Map<String, dynamic> json) {
    return OrderDeliveryConfirmModel(
      orderId: json['orderId']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      qrPayload: json['qrPayload']?.toString() ?? '',
    );
  }
}
