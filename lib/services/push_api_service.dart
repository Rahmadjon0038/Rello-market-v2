import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:hello_flutter_app/config/api_config.dart';
import 'package:hello_flutter_app/services/auth_api_service.dart';

class PushApiService {
  PushApiService({HttpClient? client, AuthApiService? authApi})
    : _client = client ?? HttpClient(),
      _authApi = authApi ?? AuthApiService();

  final HttpClient _client;
  final AuthApiService _authApi;

  static const Duration _requestTimeout = Duration(seconds: 12);

  Future<bool> registerDeviceToken({
    required String token,
    required String platform,
  }) async {
    final session = await _authApi.loadSavedSession();
    if (session == null) return false;
    await _post(
      '/push/token',
      accessToken: session.accessToken,
      body: {'token': token, 'platform': platform},
    );
    return true;
  }

  Future<bool> unregisterDeviceToken({required String token}) async {
    final session = await _authApi.loadSavedSession();
    if (session == null) return false;
    await _delete(
      '/push/token',
      accessToken: session.accessToken,
      body: {'token': token},
    );
    return true;
  }

  Future<Map<String, dynamic>> sendTestPush({
    String? title,
    String? body,
    Map<String, dynamic>? data,
  }) async {
    final session = await _authApi.loadSavedSession();
    if (session == null) {
      throw const AuthApiException('Avval tizimga kiring');
    }

    final payload = <String, dynamic>{
      if ((title ?? '').trim().isNotEmpty) 'title': title!.trim(),
      if ((body ?? '').trim().isNotEmpty) 'body': body!.trim(),
      if (data != null && data.isNotEmpty) 'data': data,
    };
    return await _post('/push/test', accessToken: session.accessToken, body: payload);
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    required String accessToken,
    required Map<String, dynamic> body,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    try {
      _client.connectionTimeout ??= _requestTimeout;
      final request = await _client.postUrl(uri).timeout(_requestTimeout);
      request.headers.contentType = ContentType.json;
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer $accessToken',
      );
      request.write(jsonEncode(body));

      final response = await request.close().timeout(_requestTimeout);
      final rawBody = await response
          .transform(utf8.decoder)
          .join()
          .timeout(_requestTimeout);
      final decoded = _decodeJson(rawBody);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthApiException(
          decoded['error']?.toString() ??
              decoded['message']?.toString() ??
              'Server xatosi',
          statusCode: response.statusCode,
        );
      }
      return decoded;
    } on TimeoutException {
      throw const AuthApiException('Server javob bermadi (timeout)');
    } on SocketException catch (e) {
      final details = (e.osError?.message ?? '').trim();
      throw AuthApiException(
        "Serverga ulanib bo'lmadi (${uri.host}:${uri.port})"
        "${details.isEmpty ? '' : ': $details'}",
      );
    } on HandshakeException {
      throw AuthApiException(
        "SSL xatosi (${uri.host}:${uri.port}). API_BASE_URL noto'g'ri bo'lishi mumkin.",
      );
    } on HttpException catch (e) {
      throw AuthApiException(
        "HTTP xato (${uri.host}:${uri.port}): ${e.message}",
      );
    }
  }

  Future<Map<String, dynamic>> _delete(
    String path, {
    required String accessToken,
    required Map<String, dynamic> body,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    try {
      _client.connectionTimeout ??= _requestTimeout;
      final request = await _client.deleteUrl(uri).timeout(_requestTimeout);
      request.headers.contentType = ContentType.json;
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer $accessToken',
      );
      request.write(jsonEncode(body));

      final response = await request.close().timeout(_requestTimeout);
      final rawBody = await response
          .transform(utf8.decoder)
          .join()
          .timeout(_requestTimeout);
      final decoded = _decodeJson(rawBody);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthApiException(
          decoded['error']?.toString() ??
              decoded['message']?.toString() ??
              'Server xatosi',
          statusCode: response.statusCode,
        );
      }
      return decoded;
    } on TimeoutException {
      throw const AuthApiException('Server javob bermadi (timeout)');
    } on SocketException catch (e) {
      final details = (e.osError?.message ?? '').trim();
      throw AuthApiException(
        "Serverga ulanib bo'lmadi (${uri.host}:${uri.port})"
        "${details.isEmpty ? '' : ': $details'}",
      );
    } on HandshakeException {
      throw AuthApiException(
        "SSL xatosi (${uri.host}:${uri.port}). API_BASE_URL noto'g'ri bo'lishi mumkin.",
      );
    } on HttpException catch (e) {
      throw AuthApiException(
        "HTTP xato (${uri.host}:${uri.port}): ${e.message}",
      );
    }
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
