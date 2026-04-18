import 'dart:convert';
import 'dart:io';

import 'package:hello_flutter_app/config/api_config.dart';
import 'package:hello_flutter_app/models/seller_application.dart';
import 'package:hello_flutter_app/models/store.dart';
import 'package:hello_flutter_app/services/auth_api_service.dart';

class SellerApplicationCreateInput {
  final String firstName;
  final String lastName;
  final String phone;
  final String storeName;
  final String purpose;
  final String productsInfo;
  final String address;

  const SellerApplicationCreateInput({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.storeName,
    required this.purpose,
    required this.productsInfo,
    required this.address,
  });

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      if (storeName.isNotEmpty) 'storeName': storeName,
      'purpose': purpose,
      'productsInfo': productsInfo,
      'address': address,
    };
  }
}

class StoreApiService {
  StoreApiService({HttpClient? client, AuthApiService? authApi})
    : _client = client ?? HttpClient(),
      _authApi = authApi ?? AuthApiService();

  final HttpClient _client;
  final AuthApiService _authApi;

  Future<SellerApplication?> getMyApplication() async {
    final data = await _send('GET', '/seller-applications/me');
    final raw = data['application'];
    if (raw is Map<String, dynamic>) return SellerApplication.fromJson(raw);
    return null;
  }

  Future<SellerApplication> createSellerApplication(
    SellerApplicationCreateInput input,
  ) async {
    final data = await _send(
      'POST',
      '/seller-applications',
      body: input.toJson(),
    );
    final raw = data['application'];
    if (raw is Map<String, dynamic>) return SellerApplication.fromJson(raw);
    throw const AuthApiException("Ariza javobi noto'g'ri formatda");
  }

  Future<List<SellerApplication>> getAdminSellerApplications({
    String? status,
  }) async {
    final query = status == null || status.isEmpty ? '' : '?status=$status';
    final data = await _send('GET', '/admin/seller-applications$query');
    final raw = data['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(SellerApplication.fromJson)
        .toList();
  }

  Future<void> approveSellerApplication(String id) async {
    await _send('PATCH', '/admin/seller-applications/$id/approve', body: {});
  }

  Future<void> rejectSellerApplication(String id, {String reviewNote = ''}) {
    return _send(
      'PATCH',
      '/admin/seller-applications/$id/reject',
      body: {if (reviewNote.trim().isNotEmpty) 'reviewNote': reviewNote.trim()},
    );
  }

  Future<List<StoreModel>> getMyStores() async {
    final data = await _send('GET', '/me/stores');
    final raw = data['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(StoreModel.fromJson)
        .toList();
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final session = await _authApi.loadSavedSession();
    if (session == null) throw const AuthApiException('Avval tizimga kiring');

    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final request = await _client.openUrl(method, uri);
    request.headers.contentType = ContentType.json;
    request.headers.set(
      HttpHeaders.authorizationHeader,
      'Bearer ${session.accessToken}',
    );
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
    final decoded = jsonDecode(rawBody);
    if (decoded is Map<String, dynamic>) return decoded;
    throw const AuthApiException("Server javobi noto'g'ri formatda");
  }
}
