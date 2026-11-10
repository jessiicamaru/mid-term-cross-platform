import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Hiển thị `hinhanh`: hỗ trợ data URI base64 (ảnh chọn từ máy) hoặc URL.
class UserAvatar extends StatelessWidget {
  final String hinhanh;
  final String initials;
  final double radius;

  const UserAvatar({super.key, required this.hinhanh, required this.initials, this.radius = 24});

  static final Map<String, Uint8List> _cache = {};

  static Uint8List? decodeDataUri(String value) {
    if (!value.startsWith('data:')) return null;
    final cached = _cache[value];
    if (cached != null) return cached;
    try {
      final bytes = base64Decode(value.substring(value.indexOf(',') + 1));
      if (_cache.length > 100) _cache.clear();
      return _cache[value] = bytes;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fallback = Text(
      initials,
      style: TextStyle(
        fontSize: radius * 0.7,
        fontWeight: FontWeight.w600,
        color: scheme.onPrimaryContainer,
      ),
    );

    Widget? image;
    final bytes = decodeDataUri(hinhanh);
    if (bytes != null) {
      image = Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true);
    } else if (hinhanh.startsWith('http')) {
      image = Image.network(
        hinhanh,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Center(child: fallback),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      child: image == null
          ? fallback
          : ClipOval(child: SizedBox.square(dimension: radius * 2, child: image)),
    );
  }
}
