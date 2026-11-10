import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'auth.dart';
import 'config.dart';
import 'user_repository.dart';

final _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

/// Giới hạn kích thước chuỗi hình ảnh (URL hoặc data URI base64) ~ 3MB.
const _maxImageLength = 3 * 1024 * 1024;

class Api {
  final Config config;
  final UserRepository repo;
  final TokenService tokens;

  Api(this.config, this.repo, this.tokens);

  Handler get handler {
    final r = Router()
      ..get('/health', _health)
      ..post('/api/login', _login)
      ..post('/api/register', _register)
      // Người dùng đã đăng nhập
      ..get('/api/me', _auth(_me))
      ..put('/api/me', _auth(_updateMe))
      // Module admin
      ..get('/api/stats', _admin(_stats))
      ..get('/api/users', _admin(_listUsers))
      ..post('/api/users', _admin(_createUser))
      ..get('/api/users/<email>', _admin(_getUser))
      ..put('/api/users/<email>', _admin(_updateUser))
      ..delete('/api/users/<email>', _admin(_deleteUser));

    return const Pipeline()
        .addMiddleware(_cors())
        .addMiddleware(_errors())
        .addMiddleware(logRequests())
        .addHandler(r.call);
  }

  // ---------------------------------------------------------------- handlers

  Future<Response> _health(Request req) async {
    await repo.ping();
    return _ok({'status': 'ok'});
  }

  Future<Response> _login(Request req) async {
    final body = await _json(req);
    final email = _str(body['email']).toLowerCase();
    final matkhau = _str(body['matkhau']);
    if (email.isEmpty || matkhau.isEmpty) {
      return _fail(400, 'Vui lòng nhập email và mật khẩu');
    }
    final user = await repo.findByEmail(email);
    if (user == null || user['matkhau'] != matkhau) {
      return _fail(401, 'Email hoặc mật khẩu không chính xác');
    }
    return _ok({
      'token': tokens.issue(email),
      'isAdmin': config.isAdmin(email),
      'user': user,
    }, message: 'Đăng nhập thành công');
  }

  Future<Response> _register(Request req) async {
    final body = await _json(req);
    final res = await _insert(body);
    if (res.statusCode != 201) return res;
    final email = _str(body['email']).toLowerCase();
    return _ok({
      'token': tokens.issue(email),
      'isAdmin': config.isAdmin(email),
      'user': await repo.findByEmail(email),
    }, status: 201, message: 'Đăng ký thành công');
  }

  Future<Response> _me(Request req) async {
    final user = await repo.findByEmail(_currentEmail(req));
    if (user == null) return _fail(404, 'Tài khoản không còn tồn tại');
    return _ok({'user': user, 'isAdmin': config.isAdmin(user['email'] as String)});
  }

  Future<Response> _updateMe(Request req) =>
      _patch(_currentEmail(req), req);

  Future<Response> _stats(Request req) async => _ok(await repo.stats());

  Future<Response> _listUsers(Request req) async {
    final q = req.url.queryParameters;
    final users = await repo.findAll(
      search: q['search'],
      sortBy: q['sortBy'] ?? 'hoten',
      descending: (q['sortOrder'] ?? '').toUpperCase() == 'DESC',
    );
    return _ok(users);
  }

  Future<Response> _getUser(Request req) async {
    final user = await repo.findByEmail(_param(req));
    if (user == null) return _fail(404, 'Không tìm thấy người dùng');
    return _ok(user);
  }

  Future<Response> _createUser(Request req) async => _insert(await _json(req));

  Future<Response> _updateUser(Request req) => _patch(_param(req), req);

  Future<Response> _deleteUser(Request req) async {
    final email = _param(req).toLowerCase();
    if (email == _currentEmail(req)) {
      return _fail(400, 'Không thể tự xoá tài khoản đang đăng nhập');
    }
    if (!await repo.delete(email)) return _fail(404, 'Không tìm thấy người dùng để xoá');
    return _ok({'email': email}, message: 'Xoá người dùng thành công');
  }

  // ----------------------------------------------------------------- helpers

  Future<Response> _insert(Map<String, dynamic> body) async {
    final email = _str(body['email']).toLowerCase();
    final matkhau = _str(body['matkhau']);
    final hoten = _str(body['hoten']);
    final hinhanh = _str(body['hinhanh']);

    final error = _validate(email: email, matkhau: matkhau, hoten: hoten, hinhanh: hinhanh);
    if (error != null) return _fail(400, error);
    if (await repo.findByEmail(email) != null) {
      return _fail(409, 'Email này đã tồn tại trong hệ thống');
    }
    final user = await repo.create(email: email, matkhau: matkhau, hoten: hoten, hinhanh: hinhanh);
    return _ok(user, status: 201, message: 'Thêm người dùng thành công');
  }

  /// Cập nhật một phần: trường nào không gửi lên thì giữ nguyên.
  Future<Response> _patch(String email, Request req) async {
    final body = await _json(req);
    final matkhau = body.containsKey('matkhau') ? _str(body['matkhau']) : null;
    final hoten = body.containsKey('hoten') ? _str(body['hoten']) : null;
    final hinhanh = body.containsKey('hinhanh') ? _str(body['hinhanh']) : null;

    final error = _validate(matkhau: matkhau, hoten: hoten, hinhanh: hinhanh);
    if (error != null) return _fail(400, error);

    final user = await repo.update(email, matkhau: matkhau, hoten: hoten, hinhanh: hinhanh);
    if (user == null) return _fail(404, 'Không tìm thấy người dùng để cập nhật');
    return _ok(user, message: 'Cập nhật thông tin thành công');
  }

  /// Trường null = không kiểm tra (dùng cho cập nhật một phần).
  String? _validate({String? email, String? matkhau, String? hoten, String? hinhanh}) {
    if (email != null && !_emailRegex.hasMatch(email)) return 'Email không hợp lệ';
    if (matkhau != null && matkhau.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
    if (hoten != null && hoten.isEmpty) return 'Họ tên không được để trống';
    if (hinhanh != null && hinhanh.length > _maxImageLength) return 'Hình ảnh quá lớn (tối đa ~2MB)';
    return null;
  }

  Handler _auth(Handler inner) => (Request req) async {
        final header = req.headers['authorization'] ?? '';
        final token = header.startsWith('Bearer ') ? header.substring(7) : '';
        final email = tokens.verify(token);
        if (email == null) return _fail(401, 'Phiên đăng nhập không hợp lệ hoặc đã hết hạn');
        return inner(req.change(context: {'email': email}));
      };

  Handler _admin(Handler inner) => _auth((Request req) {
        if (!config.isAdmin(_currentEmail(req))) {
          return _fail(403, 'Bạn không có quyền truy cập module admin');
        }
        return inner(req);
      });

  static String _currentEmail(Request req) => req.context['email'] as String;

  static String _param(Request req) => Uri.decodeComponent(req.params['email']!);

  static String _str(Object? v) => v == null ? '' : v.toString().trim();

  static Future<Map<String, dynamic>> _json(Request req) async {
    final text = await req.readAsString();
    if (text.isEmpty) return {};
    final data = jsonDecode(text);
    if (data is! Map<String, dynamic>) throw const FormatException('Body phải là JSON object');
    return data;
  }

  static Response _ok(Object? data, {int status = 200, String? message}) => Response(
        status,
        body: jsonEncode({'success': true, 'message': ?message, 'data': data}),
        headers: _jsonHeaders,
      );

  static Response _fail(int status, String message) => Response(
        status,
        body: jsonEncode({'success': false, 'message': message}),
        headers: _jsonHeaders,
      );

  static const _jsonHeaders = {'content-type': 'application/json; charset=utf-8'};

  static Middleware _cors() {
    const headers = {
      'access-control-allow-origin': '*',
      'access-control-allow-methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'access-control-allow-headers': 'Origin, Content-Type, Authorization',
    };
    return (inner) => (req) async {
          if (req.method == 'OPTIONS') return Response.ok(null, headers: headers);
          final res = await inner(req);
          return res.change(headers: headers);
        };
  }

  static Middleware _errors() => (inner) => (req) async {
        try {
          return await inner(req);
        } on FormatException catch (e) {
          return _fail(400, 'Dữ liệu gửi lên không hợp lệ: ${e.message}');
        } on PgException catch (e) {
          print('Database error: $e');
          return _fail(500, 'Lỗi cơ sở dữ liệu');
        }
      };
}
