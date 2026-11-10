import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/nguoi_dung.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

enum SortField { hoten, email }

/// Danh sách người dùng cho module admin: tìm kiếm, sắp xếp, thống kê, CRUD.
class UserProvider extends ChangeNotifier {
  final AuthProvider auth;

  UserProvider(this.auth);

  ApiService get _api => auth.api;

  List<NguoiDung> _users = [];
  UserStats _stats = const UserStats();
  bool _loading = false;
  String? _error;
  String _search = '';
  SortField _sortField = SortField.hoten;
  bool _desc = false;
  Timer? _debounce;

  List<NguoiDung> get users => _users;
  UserStats get stats => _stats;
  bool get loading => _loading;
  String? get error => _error;
  String get search => _search;
  SortField get sortField => _sortField;
  bool get desc => _desc;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _api.getUsers(search: _search, sortBy: _sortField.name, desc: _desc),
        _api.getStats(),
      ]);
      _users = results[0] as List<NguoiDung>;
      _stats = results[1] as UserStats;
    } on ApiException catch (e) {
      _error = e.message;
      if (e.isUnauthorized) await auth.logout();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Tìm kiếm với debounce để không gọi API mỗi lần gõ phím.
  void setSearch(String value) {
    _search = value.trim();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), load);
  }

  void setSort(SortField field, bool desc) {
    _sortField = field;
    _desc = desc;
    load();
  }

  Future<void> create(NguoiDung u) async {
    await _api.createUser(u);
    await load();
  }

  Future<NguoiDung> update(String email, Map<String, dynamic> changes) async {
    final updated = await _api.updateUser(email, changes);
    auth.syncCurrentUser(updated);
    await load();
    return updated;
  }

  Future<void> delete(String email) async {
    await _api.deleteUser(email);
    await load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
