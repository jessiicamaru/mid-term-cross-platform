import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:midterm_user_management/main.dart';
import 'package:midterm_user_management/models/nguoi_dung.dart';
import 'package:midterm_user_management/providers/auth_provider.dart';
import 'package:midterm_user_management/services/api_service.dart';

void main() {
  test('NguoiDung chỉ có 4 trường email, matkhau, hoten, hinhanh', () {
    final u = NguoiDung.fromJson({
      'email': 'a@b.com',
      'matkhau': '123456',
      'hoten': 'Nguyễn Văn A',
      'hinhanh': null,
    });
    expect(u.toJson().keys, ['email', 'matkhau', 'hoten', 'hinhanh']);
    expect(u.hinhanh, '');
    expect(u.initials, 'NA');
  });

  testWidgets('Chưa đăng nhập thì hiển thị màn hình đăng nhập', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final auth = AuthProvider(ApiService(baseUrl: 'http://localhost:1'));
    await auth.init();

    await tester.pumpWidget(MyApp(auth: auth));
    await tester.pumpAndSettle();

    expect(find.text('Đăng nhập'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsOneWidget);
  });
}
