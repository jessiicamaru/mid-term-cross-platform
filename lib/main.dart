import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'screens/admin/user_list_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'services/api_service.dart';

void main() {
  // Cần khởi tạo binding trước khi dùng plugin (SharedPreferences) trên Android/iOS.
  WidgetsFlutterBinding.ensureInitialized();
  final auth = AuthProvider(ApiService(baseUrl: ApiService.defaultBaseUrl))..init();
  runApp(MyApp(auth: auth));
}

class MyApp extends StatelessWidget {
  final AuthProvider auth;

  const MyApp({super.key, required this.auth});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => UserProvider(auth)),
      ],
      child: MaterialApp(
        title: 'Quản lý người dùng',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        darkTheme: ThemeData(colorSchemeSeed: Colors.indigo, brightness: Brightness.dark, useMaterial3: true),
        // Chạm ra ngoài ô nhập để ẩn bàn phím (tiện trên di động).
        builder: (context, child) => GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: child,
        ),
        home: const _Root(),
      ),
    );
  }
}

/// Điều hướng theo trạng thái: chưa đăng nhập -> Login; admin -> module admin; còn lại -> hồ sơ.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.initializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!auth.isLoggedIn) return const LoginScreen();
    return auth.isAdmin ? const UserListScreen() : const ProfileScreen();
  }
}
