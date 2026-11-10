import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/nguoi_dung.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../widgets/password_text.dart';
import '../widgets/user_avatar.dart';
import 'user_form_screen.dart';

/// Hiển thị đầy đủ thông tin một người dùng (dùng cho cả admin và hồ sơ cá nhân).
class UserInfoCard extends StatelessWidget {
  final NguoiDung user;

  const UserInfoCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        GestureDetector(
          onTap: user.coAnh ? () => _viewImage(context) : null,
          child: Hero(
            tag: 'avatar-${user.email}',
            child: UserAvatar(hinhanh: user.hinhanh, initials: user.initials, radius: 64),
          ),
        ),
        const SizedBox(height: 16),
        Text(user.hoten, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('Email'),
                subtitle: Text(user.email),
                trailing: IconButton(
                  tooltip: 'Sao chép',
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: user.email));
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('Đã sao chép email')));
                  },
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Họ tên'),
                subtitle: Text(user.hoten),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Mật khẩu'),
                subtitle: PasswordText(user.matkhau),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: const Text('Hình ảnh'),
                subtitle: Text(
                  !user.coAnh
                      ? 'Chưa có ảnh'
                      : user.hinhanh.startsWith('data:')
                          ? 'Ảnh tải lên (${(user.hinhanh.length * 3 / 4 / 1024).toStringAsFixed(0)} KB)'
                          : user.hinhanh,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _viewImage(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: InteractiveViewer(
          child: UserAvatar.decodeDataUri(user.hinhanh) != null
              ? Image.memory(UserAvatar.decodeDataUri(user.hinhanh)!)
              : Image.network(user.hinhanh),
        ),
      ),
    );
  }
}

/// Chi tiết người dùng trong module admin: xem, sửa, xoá.
class UserDetailScreen extends StatefulWidget {
  final NguoiDung user;

  const UserDetailScreen({super.key, required this.user});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  late NguoiDung _user = widget.user;

  Future<void> _edit() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => UserFormScreen(mode: FormMode.edit, user: _user)),
    );
    if (ok == true && mounted) {
      final fresh = context.read<UserProvider>().users.where((u) => u.email == _user.email);
      if (fresh.isNotEmpty) setState(() => _user = fresh.first);
    }
  }

  Future<void> _delete() async {
    if (await confirmDelete(context, _user) && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSelf = context.watch<AuthProvider>().user?.email == _user.email;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin người dùng'),
        actions: [
          IconButton(tooltip: 'Sửa', onPressed: _edit, icon: const Icon(Icons.edit_outlined)),
          if (!isSelf)
            IconButton(tooltip: 'Xoá', onPressed: _delete, icon: const Icon(Icons.delete_outline)),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: UserInfoCard(user: _user),
          ),
        ),
      ),
    );
  }
}

/// Hộp thoại xác nhận rồi xoá. Trả về true nếu đã xoá thành công.
Future<bool> confirmDelete(BuildContext context, NguoiDung user) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.warning_amber_rounded),
      title: const Text('Xoá người dùng?'),
      content: Text('Bạn có chắc muốn xoá "${user.hoten}" (${user.email})? '
          'Thao tác này không thể hoàn tác.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Xoá'),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return false;
  final messenger = ScaffoldMessenger.of(context);
  try {
    await context.read<UserProvider>().delete(user.email);
    messenger.showSnackBar(SnackBar(content: Text('Đã xoá ${user.hoten}')));
    return true;
  } on ApiException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
    return false;
  }
}
