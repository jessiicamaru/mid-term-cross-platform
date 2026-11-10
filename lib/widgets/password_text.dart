import 'package:flutter/material.dart';

/// Hiển thị mật khẩu dạng ẩn (••••) kèm nút bật/tắt xem.
class PasswordText extends StatefulWidget {
  final String matkhau;
  final TextStyle? style;

  const PasswordText(this.matkhau, {super.key, this.style});

  @override
  State<PasswordText> createState() => _PasswordTextState();
}

class _PasswordTextState extends State<PasswordText> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            _visible ? widget.matkhau : '•' * widget.matkhau.length.clamp(6, 12),
            style: widget.style,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          iconSize: 18,
          tooltip: _visible ? 'Ẩn mật khẩu' : 'Xem mật khẩu',
          onPressed: () => setState(() => _visible = !_visible),
          icon: Icon(_visible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
        ),
      ],
    );
  }
}
