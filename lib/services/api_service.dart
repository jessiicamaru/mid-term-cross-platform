import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/nguoi_dung.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

class LoginResult {
  final String token;
  final bool isAdmin;
  final NguoiDung user;

  LoginResult(this.token, this.isAdmin, this.user);
}

class UserStats {
  final int tongSo;
  final int coAnh;
  final int khongAnh;

  const UserStats({this.tongSo = 0, this.coAnh = 0, this.khongAnh = 0});

  factory UserStats.fromJson(Map<String, dynamic> j) => UserStats(
        tongSo: j['tongSo'] as int,
        coAnh: j['coAnh'] as int,
        khongAnh: j['khongAnh'] as int,
      );
}

/// Gọi API server Dart (thư mục `server/`), server này kết nối PostgreSQL.
class ApiService {
  /// Địa chỉ mặc định: có thể ghi đè bằng `--dart-define=API_URL=http://...`
  /// hoặc đổi trong màn hình đăng nhập (biểu tượng cài đặt).
  static String get defaultBaseUrl {
    const fromEnv = String.fromEnvironment('API_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    // Máy ảo Android truy cập máy host qua 10.0.2.2
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  String baseUrl;
  String? token;
  final http.Client _client;

  ApiService({required this.baseUrl, this.token, http.Client? client})
      : _client = client ?? http.Client();

  // ------------------------------------------------------------------ auth

  Future<LoginResult> login(String email, String matkhau) async {
    final data = await _send('POST', '/api/login', body: {'email': email, 'matkhau': matkhau});
    return _loginResult(data);
  }

  Future<LoginResult> register(NguoiDung u) async =>
      _loginResult(await _send('POST', '/api/register', body: u.toJson()));

  Future<(NguoiDung, bool)> me() async {
    final data = await _send('GET', '/api/me') as Map<String, dynamic>;
    return (NguoiDung.fromJson(data['user']), data['isAdmin'] as bool);
  }

  Future<NguoiDung> updateMe(Map<String, dynamic> changes) async =>
      NguoiDung.fromJson(await _send('PUT', '/api/me', body: changes));

  // ----------------------------------------------------------------- admin

  Future<List<NguoiDung>> getUsers({String? search, String sortBy = 'hoten', bool desc = false}) async {
    final data = await _send('GET', '/api/users', query: {
      if (search != null && search.isNotEmpty) 'search': search,
      'sortBy': sortBy,
      'sortOrder': desc ? 'DESC' : 'ASC',
    }) as List;
    return data.map((e) => NguoiDung.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<NguoiDung> getUser(String email) async =>
      NguoiDung.fromJson(await _send('GET', '/api/users/${Uri.encodeComponent(email)}'));

  Future<NguoiDung> createUser(NguoiDung u) async =>
      NguoiDung.fromJson(await _send('POST', '/api/users', body: u.toJson()));

  Future<NguoiDung> updateUser(String email, Map<String, dynamic> changes) async =>
      NguoiDung.fromJson(await _send('PUT', '/api/users/${Uri.encodeComponent(email)}', body: changes));

  Future<void> deleteUser(String email) => _send('DELETE', '/api/users/${Uri.encodeComponent(email)}');

  Future<UserStats> getStats() async =>
      UserStats.fromJson(await _send('GET', '/api/stats'));

  Future<void> health() => _send('GET', '/health');

  // --------------------------------------------------------------- private

  LoginResult _loginResult(dynamic data) => LoginResult(
        data['token'] as String,
        data['isAdmin'] as bool,
        NguoiDung.fromJson(data['user'] as Map<String, dynamic>),
      );

  Future<dynamic> _send(String method, String path,
      {Map<String, dynamic>? body, Map<String, String>? query}) async {
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    var uri = Uri.parse('$base$path');
    if (query != null) uri = uri.replace(queryParameters: query);

    final request = http.Request(method, uri)
      ..headers['Content-Type'] = 'application/json'
      ..headers['Accept'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) request.body = jsonEncode(body);

    final http.Response res;
    try {
      res = await http.Response.fromStream(
          await _client.send(request).timeout(const Duration(seconds: 15)));
    } on TimeoutException {
      throw ApiException('Máy chủ không phản hồi ($base)');
    } catch (_) {
      throw ApiException('Không kết nối được máy chủ $base');
    }

    Map<String, dynamic> json;
    try {
      json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Phản hồi không hợp lệ từ máy chủ (HTTP ${res.statusCode})', res.statusCode);
    }
    if (res.statusCode >= 400 || json['success'] != true) {
      throw ApiException((json['message'] ?? 'Lỗi không xác định') as String, res.statusCode);
    }
    return json['data'];
  }
}
