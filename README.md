# Quản lý người dùng (Flutter + PostgreSQL)

Ứng dụng module admin: đăng nhập, thêm / hiển thị / sửa / xoá người dùng, chọn và hiển thị ảnh đại diện.
Chạy trên **web** và **di động** (Android/iOS). Toàn bộ code viết bằng **Dart/Flutter** (không còn Node.js).

📖 Hướng dẫn sử dụng từng bước: [HUONG_DAN.md](HUONG_DAN.md) · 🎬 Video demo: [demo/demo_mobile.mp4](demo/demo_mobile.mp4)

Bảng `nguoidung` **chỉ có 4 trường**: `email` (khoá chính), `matkhau`, `hoten`, `hinhanh`.

## Kiến trúc

```
Flutter app (web / mobile)  --HTTP/JSON-->  API server Dart (server/)  -->  PostgreSQL
                                                                         pgAdmin (quản trị DB)
```

Trình duyệt không thể kết nối trực tiếp tới PostgreSQL, nên có một API server nhỏ viết bằng Dart
(`shelf` + `postgres`) nằm trong thư mục `server/`, chạy bằng Docker cùng với Postgres và pgAdmin.

| Thư mục | Nội dung |
|---|---|
| `lib/` | App Flutter (models, services, providers, screens, widgets) |
| `server/` | API server Dart + Dockerfile |
| `docker/init.sql` | Tạo bảng `nguoidung` + dữ liệu mẫu |
| `docker-compose.yml` | postgres, pgadmin, api |

## Chạy

### 1. Khởi động database + API

```bash
docker compose up -d --build
```

- API: http://localhost:8080 (kiểm tra: http://localhost:8080/health)
- pgAdmin: http://localhost:5050 (đã tự đăng ký server `midterm_postgres`, mật khẩu DB: `postgrespassword`)
- PostgreSQL: `localhost:5432`, user `postgres`, db `midterm_db`

Reset dữ liệu về ban đầu: `docker compose down -v` rồi chạy lại lệnh trên.

### 2. Chạy app Flutter

Web:

```bash
flutter run -d chrome
```

Android emulator (tự dùng `http://10.0.2.2:8080`):

```bash
flutter run -d emulator-5554
```

Điện thoại thật: bấm biểu tượng ⚙ trên màn hình đăng nhập, nhập `http://<IP-máy-tính>:8080`,
hoặc chạy với `--dart-define=API_URL=http://192.168.1.10:8080`.

### Tài khoản mẫu

| Email | Mật khẩu | Vai trò |
|---|---|---|
| admin@midterm.com | admin123 | Admin |
| nguyenvana@gmail.com | 123456 | Người dùng |
| tranthib@gmail.com | 123456 | Người dùng |
| levanc@gmail.com | 123456 | Người dùng |

Quyền admin được cấu hình bằng biến môi trường `ADMIN_EMAILS` trong `docker-compose.yml`
(không thêm cột vào DB).

## Chức năng

- Đăng nhập / đăng xuất, ghi nhớ đăng nhập, đăng ký tài khoản mới
- Module admin: danh sách người dùng (bảng trên web, thẻ trên di động) hiển thị đủ
  email, mật khẩu (ẩn/hiện), họ tên, hình ảnh
- Thêm, sửa, xoá người dùng (có hộp thoại xác nhận, vuốt để xoá trên di động, không cho tự xoá chính mình)
- Tìm kiếm theo họ tên / email, sắp xếp A-Z / Z-A, thống kê (tổng, có ảnh, không ảnh)
- Chọn ảnh từ thư viện, chụp ảnh (di động), chọn file (web) hoặc nhập URL; ảnh được nén và lưu
  vào trường `hinhanh` dưới dạng base64
- Xem chi tiết người dùng, phóng to ảnh, sao chép email
- Hồ sơ cá nhân: người dùng thường tự sửa họ tên, ảnh, mật khẩu
- Kéo để làm mới, giao diện sáng/tối theo hệ thống, đổi địa chỉ API server ngay trong app

## API

| Method | Đường dẫn | Quyền |
|---|---|---|
| POST | `/api/login` | công khai |
| POST | `/api/register` | công khai |
| GET / PUT | `/api/me` | đã đăng nhập |
| GET | `/api/users?search=&sortBy=hoten\|email&sortOrder=ASC\|DESC` | admin |
| GET / PUT / DELETE | `/api/users/{email}` | admin |
| POST | `/api/users` | admin |
| GET | `/api/stats` | admin |
