import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'user_form_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  final _matkhau = TextEditingController();
  bool _obscure = true;
  bool _remember = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: context.read<AuthProvider>().lastEmail);
  }

  @override
  void dispose() {
    _email.dispose();
    _matkhau.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().login(_email.text, _matkhau.text, remember: _remember);
    } on ApiException catch (e) {
      if (mounted) _snack(e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _serverSettings() async {
    final auth = context.read<AuthProvider>();
    final controller = TextEditingController(text: auth.baseUrl);
    String? status;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Địa chỉ API server'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(hintText: 'http://localhost:8080'),
              ),
              const SizedBox(height: 8),
              Text(
                'Web: http://localhost:8080 • Máy ảo Android: http://10.0.2.2:8080 • '
                'Điện thoại thật: http://<IP máy tính>:8080',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              if (status != null) ...[
                const SizedBox(height: 8),
                Text(status!),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final api = ApiService(baseUrl: controller.text.trim());
                try {
                  await api.health();
                  setDialogState(() => status = '✅ Kết nối thành công');
                } on ApiException catch (e) {
                  setDialogState(() => status = '❌ ${e.message}');
                }
              },
              child: const Text('Kiểm tra'),
            ),
            FilledButton(
              onPressed: () {
                auth.setBaseUrl(controller.text);
                Navigator.pop(ctx);
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Cấu hình server',
            onPressed: _serverSettings,
            icon: const Icon(Icons.settings_ethernet),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.manage_accounts, size: 72, color: theme.colorScheme.primary),
                  const SizedBox(height: 12),
                  Text('Quản lý người dùng',
                      textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text('Đăng nhập để tiếp tục',
                      textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập email' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _matkhau,
                    obscureText: _obscure,
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập mật khẩu' : null,
                  ),
                  CheckboxListTile(
                    value: _remember,
                    onChanged: (v) => setState(() => _remember = v ?? true),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('Ghi nhớ đăng nhập'),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    child: _loading
                        ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Đăng nhập'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const UserFormScreen(mode: FormMode.register)),
                    ),
                    child: const Text('Chưa có tài khoản? Đăng ký'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tài khoản admin mẫu: admin@midterm.com / admin123',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
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
