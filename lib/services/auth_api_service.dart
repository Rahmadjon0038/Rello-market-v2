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
  final String? profileImg;
  final String accessToken;
  final String refreshToken;

  const AuthSession({
    required this.name,
    required this.phone,
    required this.username,
    required this.role,
    this.profileImg,
    required this.accessToken,
    required this.refreshToken,
  });
}

class AuthApiService {
  AuthApiService({HttpClient? client}) : _client = client ?? HttpClient();

  static String get baseUrlForFiles => ApiConfig.baseUrl;

  static const _accessTokenKey = 'auth_access_token';
  static const _refreshTokenKey = 'auth_refresh_token';
  static const _nameKey = 'auth_name';
  static const _phoneKey = 'auth_phone';
  static const _roleKey = 'auth_role';
  static const _profileImgKey = 'auth_profile_img';

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

  Future<AuthSession> updateProfile({
    required String fullName,
    File? profileImg,
  }) async {
    final currentSession = await loadSavedSession();
    if (currentSession == null) {
      throw const AuthApiException('Avval tizimga kiring');
    }

    final nameParts = fullName.trim().split(RegExp(r'\s+'));
    final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final lastName = nameParts.length > 1 ? nameParts.skip(1).join(' ') : '';
    final data = await _patchMultipart(
      '/me',
      fields: {'firstName': firstName, 'lastName': lastName},
      fileField: 'profileImg',
      file: profileImg,
      accessToken: currentSession.accessToken,
    );

    final updatedSession = _sessionFromProfileJson(
      data,
      fallback: AuthSession(
        name: fullName.trim().isEmpty ? currentSession.name : fullName.trim(),
        phone: currentSession.phone,
        username: currentSession.username,
        role: currentSession.role,
        profileImg: currentSession.profileImg,
        accessToken: currentSession.accessToken,
        refreshToken: currentSession.refreshToken,
      ),
    );
    await saveSession(updatedSession);
    return updatedSession;
  }

  Future<CodeResponse> requestPhoneChangeCode({
    required String oldPhone,
    required String newPhone,
  }) async {
    final currentSession = await loadSavedSession();
    if (currentSession == null) {
      throw const AuthApiException('Avval tizimga kiring');
    }
    final data = await _sendJson(
      method: 'POST',
      path: '/me/phone/request-code',
      body: {'oldPhone': oldPhone, 'newPhone': newPhone},
      accessToken: currentSession.accessToken,
    );
    return CodeResponse.fromJson(data);
  }

  Future<AuthSession> verifyPhoneChangeCode({
    required String oldPhone,
    required String newPhone,
    required String code,
  }) async {
    final currentSession = await loadSavedSession();
    if (currentSession == null) {
      throw const AuthApiException('Avval tizimga kiring');
    }
    final data = await _sendJson(
      method: 'POST',
      path: '/me/phone/verify',
      body: {'oldPhone': oldPhone, 'newPhone': newPhone, 'code': code},
      accessToken: currentSession.accessToken,
    );
    final session = _sessionFromProfileJson(data, fallback: currentSession);
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
      profileImg: prefs.getString(_profileImgKey),
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
    final profileImg = session.profileImg;
    if (profileImg == null || profileImg.isEmpty) {
      await prefs.remove(_profileImgKey);
    } else {
      await prefs.setString(_profileImgKey, profileImg);
    }
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_phoneKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_profileImgKey);
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
      profileImg: json['profileImg']?.toString(),
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  Future<AuthSession> _withProfile(AuthSession fallback) async {
    try {
      final data = await _get('/me', accessToken: fallback.accessToken);
      return _sessionFromProfileJson(data, fallback: fallback);
    } on Object {
      return fallback;
    }
  }

  AuthSession _sessionFromProfileJson(
    Map<String, dynamic> json, {
    required AuthSession fallback,
  }) {
    final profile = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : json['profile'] is Map<String, dynamic>
        ? json['profile'] as Map<String, dynamic>
        : json;
    final firstName = profile['firstName']?.toString().trim() ?? '';
    final lastName = profile['lastName']?.toString().trim() ?? '';
    final fullName = [
      firstName,
      lastName,
    ].where((part) => part.isNotEmpty).join(' ').trim();
    final tokens = json['tokens'] is Map<String, dynamic>
        ? json['tokens'] as Map<String, dynamic>
        : profile['tokens'] is Map<String, dynamic>
        ? profile['tokens'] as Map<String, dynamic>
        : null;
    return AuthSession(
      name: fullName.isNotEmpty
          ? fullName
          : profile['name']?.toString() ?? fallback.name,
      phone: profile['phone']?.toString() ?? fallback.phone,
      username: profile['username']?.toString() ?? fallback.username,
      role: profile['role']?.toString() ?? fallback.role,
      profileImg: profile['profileImg']?.toString() ?? fallback.profileImg,
      accessToken:
          json['accessToken']?.toString() ??
          tokens?['accessToken']?.toString() ??
          fallback.accessToken,
      refreshToken:
          json['refreshToken']?.toString() ??
          tokens?['refreshToken']?.toString() ??
          fallback.refreshToken,
    );
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

  Future<Map<String, dynamic>> _patchMultipart(
    String path, {
    required Map<String, String> fields,
    required String fileField,
    File? file,
    required String accessToken,
  }) async {
    final boundary = '----RelloMarket${DateTime.now().microsecondsSinceEpoch}';
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final request = await _client.openUrl('PATCH', uri);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
    request.headers.set(
      HttpHeaders.contentTypeHeader,
      'multipart/form-data; boundary=$boundary',
    );

    void writeField(String name, String value) {
      request.write('--$boundary\r\n');
      request.write('Content-Disposition: form-data; name="$name"\r\n\r\n');
      request.write('$value\r\n');
    }

    for (final entry in fields.entries) {
      writeField(entry.key, entry.value);
    }

    if (file != null) {
      final fileName = file.path.split(Platform.pathSeparator).last;
      request.write('--$boundary\r\n');
      request.write(
        'Content-Disposition: form-data; name="$fileField"; filename="$fileName"\r\n',
      );
      request.write('Content-Type: ${_imageContentType(fileName)}\r\n\r\n');
      await request.addStream(file.openRead());
      request.write('\r\n');
    }

    request.write('--$boundary--\r\n');
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

  Future<Map<String, dynamic>> _sendJson({
    required String method,
    required String path,
    required Map<String, dynamic> body,
    String? accessToken,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final request = await _client.openUrl(method, uri);
    request.headers.contentType = ContentType.json;
    if (accessToken != null) {
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer $accessToken',
      );
    }
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

  Map<String, dynamic> _decodeJson(String rawBody) {
    if (rawBody.trim().isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(rawBody);
    if (decoded is Map<String, dynamic>) return decoded;
    throw const AuthApiException("Server javobi noto'g'ri formatda");
  }

  String _imageContentType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}
