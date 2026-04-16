import 'dart:convert';
import 'dart:io';

import 'package:hello_flutter_app/config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthApiException implements Exception {
  final String message;
  final int? statusCode;

  const AuthApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class CodeResponse {
  final String message;
  final String? smsCode;
  final int? expiresInSeconds;

  const CodeResponse({
    required this.message,
    this.smsCode,
    this.expiresInSeconds,
  });

  factory CodeResponse.fromJson(Map<String, dynamic> json) {
    return CodeResponse(
      message: json['message']?.toString() ?? 'SMS code yuborildi',
      smsCode: json['smsCode']?.toString(),
      expiresInSeconds: json['expiresInSeconds'] is int
          ? json['expiresInSeconds'] as int
          : int.tryParse(json['expiresInSeconds']?.toString() ?? ''),
    );
  }
}

class RegisterVerification {
  final String message;
  final String registrationToken;
  final int? expiresInSeconds;

  const RegisterVerification({
    required this.message,
    required this.registrationToken,
    this.expiresInSeconds,
  });

  factory RegisterVerification.fromJson(Map<String, dynamic> json) {
    final registrationToken = json['registrationToken']?.toString();
    if (registrationToken == null || registrationToken.isEmpty) {
      throw const AuthApiException('Registration token topilmadi');
    }

    return RegisterVerification(
      message: json['message']?.toString() ?? 'SMS code tasdiqlandi',
      registrationToken: registrationToken,
      expiresInSeconds: json['expiresInSeconds'] is int
          ? json['expiresInSeconds'] as int
          : int.tryParse(json['expiresInSeconds']?.toString() ?? ''),
    );
  }
}

class AuthSession {
  final String name;
  final String phone;
  final String username;
  final String role;
  final String accessToken;
  final String refreshToken;

  const AuthSession({
    required this.name,
    required this.phone,
    required this.username,
    required this.role,
    required this.accessToken,
    required this.refreshToken,
  });
}

class AuthApiService {
  AuthApiService({HttpClient? client}) : _client = client ?? HttpClient();

  static const _accessTokenKey = 'auth_access_token';
  static const _refreshTokenKey = 'auth_refresh_token';
  static const _nameKey = 'auth_name';
  static const _phoneKey = 'auth_phone';
  static const _roleKey = 'auth_role';

  final HttpClient _client;

  Future<AuthSession> login({
    required String phone,
    required String password,
  }) async {
    final data = await _post('/auth/login', {
      'phone': phone,
      'password': password,
    });
    final session = await _withProfile(
      _sessionFromJson(data, fallbackPhone: phone),
    );
    await saveSession(session);
    return session;
  }

  Future<CodeResponse> requestRegisterCode({required String phone}) async {
    final data = await _post('/auth/register/request-code', {'phone': phone});
    return CodeResponse.fromJson(data);
  }

  Future<RegisterVerification> verifyRegisterCode({
    required String phone,
    required String code,
  }) async {
    final data = await _post('/auth/register/verify', {
      'phone': phone,
      'code': code,
    });
    return RegisterVerification.fromJson(data);
  }

  Future<AuthSession> completeRegister({
    required String phone,
    required String registrationToken,
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    final data = await _post('/auth/register/complete', {
      'phone': phone,
      'registrationToken': registrationToken,
      'firstName': firstName,
      'lastName': lastName,
      'password': password,
    });
    final session = await _withProfile(
      _sessionFromJson(
        data,
        fallbackName: '$firstName $lastName',
        fallbackPhone: phone,
      ),
    );
    await saveSession(session);
    return session;
  }

  Future<CodeResponse> requestPasswordResetCode(String phone) async {
    final data = await _post('/auth/password-reset/request-code', {
      'phone': phone,
    });
    return CodeResponse.fromJson(data);
  }

  Future<AuthSession> verifyPasswordReset({
    required String phone,
    required String code,
    required String newPassword,
  }) async {
    final data = await _post('/auth/password-reset/verify', {
      'phone': phone,
      'code': code,
      'newPassword': newPassword,
    });
    final session = await _withProfile(
      _sessionFromJson(data, fallbackPhone: phone),
    );
    await saveSession(session);
    return session;
  }

  Future<AuthSession?> loadSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString(_accessTokenKey);
    final refreshToken = prefs.getString(_refreshTokenKey);
    final phone = prefs.getString(_phoneKey);
    if (accessToken == null || refreshToken == null || phone == null) {
      return null;
    }
    return AuthSession(
      name: prefs.getString(_nameKey) ?? phone,
      phone: phone,
      username: phone,
      role: prefs.getString(_roleKey) ?? 'user',
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  Future<void> saveSession(AuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, session.accessToken);
    await prefs.setString(_refreshTokenKey, session.refreshToken);
    await prefs.setString(_nameKey, session.name);
    await prefs.setString(_phoneKey, session.phone);
    await prefs.setString(_roleKey, session.role);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_phoneKey);
    await prefs.remove(_roleKey);
  }

  AuthSession _sessionFromJson(
    Map<String, dynamic> json, {
    String? fallbackName,
    String? fallbackPhone,
  }) {
    final phone =
        json['phone']?.toString() ??
        json['username']?.toString() ??
        fallbackPhone ??
        '';
    final accessToken = json['accessToken']?.toString();
    final refreshToken = json['refreshToken']?.toString();
    if (accessToken == null || refreshToken == null) {
      throw const AuthApiException('Token response ichida topilmadi');
    }
    return AuthSession(
      name: fallbackName?.trim().isNotEmpty == true
          ? fallbackName!.trim()
          : phone,
      phone: phone,
      username: json['username']?.toString() ?? phone,
      role: json['role']?.toString() ?? 'user',
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  Future<AuthSession> _withProfile(AuthSession fallback) async {
    try {
      final data = await _get('/me', accessToken: fallback.accessToken);
      final firstName = data['firstName']?.toString().trim() ?? '';
      final lastName = data['lastName']?.toString().trim() ?? '';
      final fullName = [
        firstName,
        lastName,
      ].where((part) => part.isNotEmpty).join(' ').trim();
      final tokens = data['tokens'];
      return AuthSession(
        name: fullName.isNotEmpty ? fullName : fallback.name,
        phone: data['phone']?.toString() ?? fallback.phone,
        username: data['username']?.toString() ?? fallback.username,
        role: data['role']?.toString() ?? fallback.role,
        accessToken: tokens is Map<String, dynamic>
            ? tokens['accessToken']?.toString() ?? fallback.accessToken
            : fallback.accessToken,
        refreshToken: tokens is Map<String, dynamic>
            ? tokens['refreshToken']?.toString() ?? fallback.refreshToken
            : fallback.refreshToken,
      );
    } on Object {
      return fallback;
    }
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final request = await _client.postUrl(uri);
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode(body));
    final response = await request.close();
    final rawBody = await response.transform(utf8.decoder).join();
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
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    required String accessToken,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final request = await _client.getUrl(uri);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
    final response = await request.close();
    final rawBody = await response.transform(utf8.decoder).join();
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
  }

  Map<String, dynamic> _decodeJson(String rawBody) {
    if (rawBody.trim().isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(rawBody);
    if (decoded is Map<String, dynamic>) return decoded;
    throw const AuthApiException("Server javobi noto'g'ri formatda");
  }
}
