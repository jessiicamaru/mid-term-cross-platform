import 'dart:io';

/// Cấu hình đọc từ biến môi trường (xem docker-compose.yml).
class Config {
  final int port;
  final String dbHost;
  final int dbPort;
  final String dbUser;
  final String dbPassword;
  final String dbName;
  final String tokenSecret;
  final Duration tokenTtl;

  /// Danh sách email có quyền admin. Bảng chỉ có 4 cột (email, matkhau,
  /// hoten, hinhanh) nên quyền admin được cấu hình ở đây, không lưu trong DB.
  final Set<String> adminEmails;

  Config._({
    required this.port,
    required this.dbHost,
    required this.dbPort,
    required this.dbUser,
    required this.dbPassword,
    required this.dbName,
    required this.tokenSecret,
    required this.tokenTtl,
    required this.adminEmails,
  });

  factory Config.fromEnv() {
    final env = Platform.environment;
    String get(String key, String fallback) {
      final v = env[key];
      return (v == null || v.isEmpty) ? fallback : v;
    }

    return Config._(
      port: int.parse(get('PORT', '8080')),
      dbHost: get('DB_HOST', 'localhost'),
      dbPort: int.parse(get('DB_PORT', '5432')),
      dbUser: get('DB_USER', 'postgres'),
      dbPassword: get('DB_PASSWORD', 'postgrespassword'),
      dbName: get('DB_NAME', 'midterm_db'),
      tokenSecret: get('TOKEN_SECRET', 'midterm-dev-secret-change-me'),
      tokenTtl: Duration(hours: int.parse(get('TOKEN_TTL_HOURS', '24'))),
      adminEmails: get('ADMIN_EMAILS', 'admin@midterm.com')
          .split(',')
          .map((e) => e.trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toSet(),
    );
  }

  bool isAdmin(String email) => adminEmails.contains(email.toLowerCase());
}
