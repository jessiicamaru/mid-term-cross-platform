-- ==============================================================
-- KHỞI TẠO CƠ SỞ DỮ LIỆU
-- Bảng nguoidung CHỈ gồm 4 trường: email, matkhau, hoten, hinhanh
-- (không bổ sung thêm trường nào khác)
-- ==============================================================

CREATE TABLE IF NOT EXISTS nguoidung (
    email   VARCHAR(255) PRIMARY KEY,
    matkhau VARCHAR(255) NOT NULL,
    hoten   VARCHAR(255) NOT NULL,
    hinhanh TEXT
);

-- Dữ liệu mẫu (admin@midterm.com là tài khoản admin, cấu hình qua ADMIN_EMAILS)
INSERT INTO nguoidung (email, matkhau, hoten, hinhanh) VALUES
    ('admin@midterm.com',    'admin123', 'Quản Trị Viên',
     'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80'),
    ('nguyenvana@gmail.com', '123456',   'Nguyễn Văn A',
     'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&w=400&q=80'),
    ('tranthib@gmail.com',   '123456',   'Trần Thị B',
     'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=400&q=80'),
    ('levanc@gmail.com',     '123456',   'Lê Văn C', '')
ON CONFLICT (email) DO NOTHING;
