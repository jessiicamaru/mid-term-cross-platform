import 'package:postgres/postgres.dart';

/// Truy cập bảng `nguoidung` — CHỈ gồm 4 cột: email, matkhau, hoten, hinhanh.
class UserRepository {
  final Pool _db;

  UserRepository(this._db);

  static const _cols = 'email, matkhau, hoten, hinhanh';

  Future<void> ensureSchema() async {
    await _db.execute('''
      CREATE TABLE IF NOT EXISTS nguoidung (
        email   VARCHAR(255) PRIMARY KEY,
        matkhau VARCHAR(255) NOT NULL,
        hoten   VARCHAR(255) NOT NULL,
        hinhanh TEXT
      )
    ''');
  }

  Future<void> ping() => _db.execute('SELECT 1');

  Future<List<Map<String, dynamic>>> findAll({
    String? search,
    String sortBy = 'hoten',
    bool descending = false,
  }) async {
    // Chỉ cho phép sắp xếp theo cột hợp lệ (chống SQL injection).
    final col = sortBy == 'email' ? 'email' : 'hoten';
    final dir = descending ? 'DESC' : 'ASC';
    final hasSearch = search != null && search.trim().isNotEmpty;
    final where = hasSearch ? 'WHERE hoten ILIKE @q OR email ILIKE @q' : '';
    final result = await _db.execute(
      Sql.named('SELECT $_cols FROM nguoidung $where ORDER BY $col $dir'),
      parameters: hasSearch ? {'q': '%${search.trim()}%'} : null,
    );
    return result.map((r) => r.toColumnMap()).toList();
  }

  Future<Map<String, dynamic>?> findByEmail(String email) async {
    final result = await _db.execute(
      Sql.named('SELECT $_cols FROM nguoidung WHERE email = @email'),
      parameters: {'email': email.toLowerCase()},
    );
    return result.isEmpty ? null : result.first.toColumnMap();
  }

  Future<Map<String, dynamic>> create({
    required String email,
    required String matkhau,
    required String hoten,
    String? hinhanh,
  }) async {
    final result = await _db.execute(
      Sql.named(
        'INSERT INTO nguoidung ($_cols) VALUES (@email, @matkhau, @hoten, @hinhanh) '
        'RETURNING $_cols',
      ),
      parameters: {
        'email': email.toLowerCase(),
        'matkhau': matkhau,
        'hoten': hoten,
        'hinhanh': hinhanh ?? '',
      },
    );
    return result.first.toColumnMap();
  }

  /// Chỉ cập nhật các trường được truyền vào (khác null).
  Future<Map<String, dynamic>?> update(
    String email, {
    String? matkhau,
    String? hoten,
    String? hinhanh,
  }) async {
    final sets = <String>[];
    final params = <String, dynamic>{'email': email.toLowerCase()};
    if (matkhau != null) {
      sets.add('matkhau = @matkhau');
      params['matkhau'] = matkhau;
    }
    if (hoten != null) {
      sets.add('hoten = @hoten');
      params['hoten'] = hoten;
    }
    if (hinhanh != null) {
      sets.add('hinhanh = @hinhanh');
      params['hinhanh'] = hinhanh;
    }
    if (sets.isEmpty) return findByEmail(email);

    final result = await _db.execute(
      Sql.named(
        'UPDATE nguoidung SET ${sets.join(', ')} WHERE email = @email RETURNING $_cols',
      ),
      parameters: params,
    );
    return result.isEmpty ? null : result.first.toColumnMap();
  }

  Future<bool> delete(String email) async {
    final result = await _db.execute(
      Sql.named('DELETE FROM nguoidung WHERE email = @email'),
      parameters: {'email': email.toLowerCase()},
    );
    return result.affectedRows > 0;
  }

  Future<Map<String, int>> stats() async {
    final result = await _db.execute(
      "SELECT COUNT(*)::int AS total, "
      "COUNT(*) FILTER (WHERE hinhanh IS NOT NULL AND hinhanh <> '')::int AS co_anh "
      "FROM nguoidung",
    );
    final row = result.first.toColumnMap();
    final total = row['total'] as int;
    final coAnh = row['co_anh'] as int;
    return {'tongSo': total, 'coAnh': coAnh, 'khongAnh': total - coAnh};
  }
}
