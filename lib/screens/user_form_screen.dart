import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/nguoi_dung.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../widgets/avatar_picker.dart';

enum FormMode {
  /// Admin thêm người dùng mới
  create,

  /// Admin sửa người dùng
  edit,

  /// Người dùng tự sửa thông tin cá nhân
  profile,

  /// Đăng ký tài khoản mới từ màn hình đăng nhập
  register,
}

/// Form nhập / sửa: email, matkhau, hoten, hinhanh.
class UserFormScreen extends StatefulWidget {
  final FormMode mode;
  final NguoiDung? user;

  const UserFormScreen({super.key, required this.mode, this.user});

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  late final TextEditingController _hoten;
  late final TextEditingController _matkhau;
  final _xacNhan = TextEditingController();
  late String _hinhanh;
  bool _obscure = true;
  bool _saving = false;

  bool get _isNew => widget.mode == FormMode.create || widget.mode == FormMode.register;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _email = TextEditingController(text: u?.email ?? '');
    _hoten = TextEditingController(text: u?.hoten ?? '');
    _matkhau = TextEditingController(text: u?.matkhau ?? '');
    _hinhanh = u?.hinhanh ?? '';
    _hoten.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _email.dispose();
    _hoten.dispose();
    _matkhau.dispose();
    _xacNhan.dispose();
    super.dispose();
  }

  String get _title => switch (widget.mode) {
        FormMode.create => 'Thêm người dùng',
        FormMode.edit => 'Sửa người dùng',
        FormMode.profile => 'Sửa thông tin cá nhân',
        FormMode.register => 'Đăng ký tài khoản',
      };

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final data = NguoiDung(
      email: _email.text.trim(),
      matkhau: _matkhau.text,
      hoten: _hoten.text.trim(),
      hinhanh: _hinhanh,
    );
    final changes = {'matkhau': data.matkhau, 'hoten': data.hoten, 'hinhanh': data.hinhanh};

    try {
      switch (widget.mode) {
        case FormMode.create:
          await context.read<UserProvider>().create(data);
        case FormMode.edit:
          await context.read<UserProvider>().update(widget.user!.email, changes);
        case FormMode.profile:
          await context.read<AuthProvider>().updateMe(changes);
        case FormMode.register:
          await context.read<AuthProvider>().register(data);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(switch (widget.mode) {
          FormMode.create => 'Đã thêm ${data.hoten}',
          FormMode.register => 'Đăng ký thành công. Xin chào ${data.hoten}!',
          _ => 'Đã lưu thay đổi',
        }),
      ));
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = NguoiDung(email: _email.text, matkhau: '', hoten: _hoten.text).initials;
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AvatarPicker(
                    value: _hinhanh,
                    initials: initials,
                    onChanged: (v) => setState(() => _hinhanh = v),
                  ),
                  const SizedBox(height: 8),
                  Text('Nhấn vào ảnh để chọn hình',
                      textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _email,
                    enabled: _isNew,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: const OutlineInputBorder(),
                      helperText: _isNew ? null : 'Email là khoá chính, không thể thay đổi',
                    ),
                    validator: (v) {
                      final s = v?.trim() ?? '';
                      if (s.isEmpty) return 'Vui lòng nhập email';
                      if (!RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$').hasMatch(s)) return 'Email không hợp lệ';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _hoten,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Họ tên',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập họ tên' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _matkhau,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 6) ? 'Mật khẩu tối thiểu 6 ký tự' : null,
                  ),
                  if (widget.mode == FormMode.register) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _xacNhan,
                      obscureText: _obscure,
                      decoration: const InputDecoration(
                        labelText: 'Nhập lại mật khẩu',
                        prefixIcon: Icon(Icons.lock_reset),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v != _matkhau.text ? 'Mật khẩu nhập lại không khớp' : null,
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    icon: _saving
                        ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save_outlined),
                    label: Text(widget.mode == FormMode.register ? 'Đăng ký' : 'Lưu'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
