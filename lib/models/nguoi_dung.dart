/// Người dùng — đúng 4 trường của bảng `nguoidung`.
class NguoiDung {
  final String email;
  final String matkhau;
  final String hoten;
  final String hinhanh;

  const NguoiDung({
    required this.email,
    required this.matkhau,
    required this.hoten,
    this.hinhanh = '',
  });

  factory NguoiDung.fromJson(Map<String, dynamic> json) => NguoiDung(
        email: (json['email'] ?? '') as String,
        matkhau: (json['matkhau'] ?? '') as String,
        hoten: (json['hoten'] ?? '') as String,
        hinhanh: (json['hinhanh'] ?? '') as String,
      );

  Map<String, dynamic> toJson() => {
        'email': email,
        'matkhau': matkhau,
        'hoten': hoten,
        'hinhanh': hinhanh,
      };

  bool get coAnh => hinhanh.isNotEmpty;

  /// Chữ cái viết tắt hiển thị khi chưa có ảnh, ví dụ "Nguyễn Văn A" -> "NA".
  String get initials {
    final parts = hoten.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return email.isEmpty ? '?' : email[0].toUpperCase();
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
