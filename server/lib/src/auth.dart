import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Token đơn giản dạng `payload.signature` (HMAC-SHA256), không cần lưu DB.
class TokenService {
  final List<int> _key;
  final Duration ttl;

  TokenService(String secret, this.ttl) : _key = utf8.encode(secret);

  String issue(String email) {
    final exp = DateTime.now().add(ttl).millisecondsSinceEpoch ~/ 1000;
    final payload = _b64(utf8.encode(jsonEncode({'email': email, 'exp': exp})));
    return '$payload.${_sign(payload)}';
  }

  /// Trả về email nếu token hợp lệ và chưa hết hạn, ngược lại trả về null.
  String? verify(String token) {
    final parts = token.split('.');
    if (parts.length != 2) return null;
    if (!_constantTimeEquals(_sign(parts[0]), parts[1])) return null;
    try {
      final data = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[0]))));
      final exp = data['exp'] as int;
      if (DateTime.now().millisecondsSinceEpoch ~/ 1000 > exp) return null;
      return data['email'] as String;
    } catch (_) {
      return null;
    }
  }

  String _sign(String payload) =>
      _b64(Hmac(sha256, _key).convert(utf8.encode(payload)).bytes);

  static String _b64(List<int> bytes) => base64Url.encode(bytes).replaceAll('=', '');

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
