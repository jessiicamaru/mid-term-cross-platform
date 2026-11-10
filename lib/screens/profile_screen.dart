import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'user_detail_screen.dart';
import 'user_form_screen.dart';

/// Hồ sơ của người dùng đang đăng nhập (màn hình chính với tài khoản không phải admin).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ của tôi'),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: auth.refreshMe,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    UserInfoCard(user: user),
                    const SizedBox(height: 16),
                    if (auth.isAdmin)
                      const Chip(
                        avatar: Icon(Icons.admin_panel_settings, size: 18),
                        label: Text('Quản trị viên'),
                      ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserFormScreen(mode: FormMode.profile, user: user),
                        ),
                      ),
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Sửa thông tin / đổi ảnh / đổi mật khẩu'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> logout(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Đăng xuất?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Đăng xuất')),
      ],
    ),
  );
  if (ok == true && context.mounted) {
    final auth = context.read<AuthProvider>();
    Navigator.of(context).popUntil((r) => r.isFirst);
    await auth.logout();
  }
}
