import 'dart:io';

import 'package:midterm_api/src/api.dart';
import 'package:midterm_api/src/auth.dart';
import 'package:midterm_api/src/config.dart';
import 'package:midterm_api/src/user_repository.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf_io.dart' as io;

Future<void> main() async {
  final config = Config.fromEnv();

  final pool = Pool.withEndpoints(
    [
      Endpoint(
        host: config.dbHost,
        port: config.dbPort,
        database: config.dbName,
        username: config.dbUser,
        password: config.dbPassword,
      ),
    ],
    settings: const PoolSettings(maxConnectionCount: 10, sslMode: SslMode.disable),
  );

  final repo = UserRepository(pool);

  // Chờ PostgreSQL sẵn sàng rồi đảm bảo bảng tồn tại.
  for (var attempt = 1;; attempt++) {
    try {
      await repo.ensureSchema();
      print('Connected to PostgreSQL ${config.dbHost}:${config.dbPort}/${config.dbName}');
      break;
    } catch (e) {
      if (attempt >= 15) rethrow;
      print('Waiting for database (attempt $attempt): $e');
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  }

  final api = Api(config, repo, TokenService(config.tokenSecret, config.tokenTtl));
  final server = await io.serve(api.handler, InternetAddress.anyIPv4, config.port);
  print('API server listening on http://${server.address.host}:${server.port}');
  print('Admin emails: ${config.adminEmails.join(', ')}');
}
