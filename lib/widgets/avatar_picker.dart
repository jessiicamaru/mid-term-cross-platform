import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'user_avatar.dart';

/// Chọn ảnh đại diện: thư viện / máy ảnh (di động) / dán URL / xoá ảnh.
/// Ảnh được nén và lưu vào trường `hinhanh` dưới dạng data URI base64.
class AvatarPicker extends StatelessWidget {
  final String value;
  final String initials;
  final ValueChanged<String> onChanged;

  const AvatarPicker({super.key, required this.value, required this.initials, required this.onChanged});

  Future<void> _pick(BuildContext context, ImageSource source) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 75,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final mime = file.mimeType ?? _mimeFromName(file.name);
      onChanged('data:$mime;base64,${base64Encode(bytes)}');
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Không chọn được ảnh: $e')));
    }
  }

  static String _mimeFromName(String name) {
    final n = name.toLowerCase();
    if (n.endsWith('.png')) return 'image/png';
    if (n.endsWith('.gif')) return 'image/gif';
    if (n.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> _enterUrl(BuildContext context) async {
    final controller = TextEditingController(text: value.startsWith('http') ? value : '');
    final url = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nhập URL hình ảnh'),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(hintText: 'https://...'),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('OK')),
        ],
      ),
    );
    controller.dispose();
    if (url != null && url.isNotEmpty) onChanged(url);
  }

  void _showOptions(BuildContext context) {
    final mobile = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(mobile ? 'Chọn từ thư viện ảnh' : 'Chọn ảnh từ máy tính'),
              onTap: () {
                Navigator.pop(ctx);
                _pick(context, ImageSource.gallery);
              },
            ),
            if (mobile)
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Chụp ảnh'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pick(context, ImageSource.camera);
                },
              ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Nhập URL hình ảnh'),
              onTap: () {
                Navigator.pop(ctx);
                _enterUrl(context);
              },
            ),
            if (value.isNotEmpty)
              ListTile(
                leading: Icon(Icons.delete_outline, color: Theme.of(ctx).colorScheme.error),
                title: const Text('Xoá ảnh'),
                onTap: () {
                  Navigator.pop(ctx);
                  onChanged('');
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => _showOptions(context),
            child: UserAvatar(hinhanh: value, initials: initials, radius: 56),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: IconButton.filled(
              tooltip: 'Đổi ảnh',
              onPressed: () => _showOptions(context),
              icon: const Icon(Icons.camera_alt, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
