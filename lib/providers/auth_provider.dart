import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/nguoi_dung.dart';
import '../services/api_service.dart';

/// Trạng thái đăng nhập + ghi nhớ phiên (token, địa chỉ server) bằng SharedPreferences.
class AuthProvider extends ChangeNotifier {
  static const _kToken = 'auth_token';
  static const _kBaseUrl = 'api_base_url';
  static const _kLastEmail = 'last_email';

  final ApiService api;

  AuthProvider(this.api);

  bool _initializing = true;
  NguoiDung? _user;
  bool _isAdmin = false;
  String _lastEmail = '';

  bool get initializing => _initializing;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _isAdmin;
  NguoiDung? get user => _user;
  String get lastEmail => _lastEmail;
  String get baseUrl => api.baseUrl;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    api.baseUrl = prefs.getString(_kBaseUrl) ?? api.baseUrl;
    _lastEmail = prefs.getString(_kLastEmail) ?? '';
    final token = prefs.getString(_kToken);
    if (token != null) {
      api.token = token;
      try {
        final (u, admin) = await api.me();
        _user = u;
        _isAdmin = admin;
      } catch (_) {
        // Token hết hạn hoặc server không chạy -> về màn hình đăng nhập.
        api.token = null;
        await prefs.remove(_kToken);
      }
    }
    _initializing = false;
    notifyListeners();
  }

  Future<void> login(String email, String matkhau, {bool remember = true}) async {
    await _applyLogin(await api.login(email.trim(), matkhau), remember: remember);
  }

  Future<void> register(NguoiDung u) async {
    await _applyLogin(await api.register(u), remember: true);
  }

  Future<void> _applyLogin(LoginResult r, {required bool remember}) async {
    api.token = r.token;
    _user = r.user;
    _isAdmin = r.isAdmin;
    _lastEmail = r.user.email;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastEmail, r.user.email);
    if (remember) {
      await prefs.setString(_kToken, r.token);
    } else {
      await prefs.remove(_kToken);
    }
  }

  Future<void> refreshMe() async {
    try {
      final (u, admin) = await api.me();
      _user = u;
      _isAdmin = admin;
      notifyListeners();
    } on ApiException catch (e) {
      if (e.isUnauthorized) await logout();
    }
  }

  Future<void> updateMe(Map<String, dynamic> changes) async {
    _user = await api.updateMe(changes);
    notifyListeners();
  }

  /// Gọi khi admin sửa chính tài khoản của mình từ danh sách.
  void syncCurrentUser(NguoiDung u) {
    if (_user?.email == u.email) {
      _user = u;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    api.token = null;
    _user = null;
    _isAdmin = false;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
  }

  Future<void> setBaseUrl(String url) async {
    api.baseUrl = url.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBaseUrl, api.baseUrl);
    notifyListeners();
  }
}
