# 🩺 Telehealth Frontend (Flutter)

## 📖 Giới thiệu
Ứng dụng di động **Telehealth** được xây dựng bằng **Flutter (Dart)**, cho phép **bệnh nhân (BN)** và **bác sĩ (BS)** tham gia khám bệnh trực tuyến.  
Người dùng có thể:
- 📅 Đặt lịch khám và nhận thông báo nhắc lịch  
- 🎥 Tham gia cuộc gọi video thời gian thực (WebRTC SDK)  
- 💬 Chat và gửi tệp (ảnh xét nghiệm, toa thuốc, ghi chú)  
- 🩻 Xem lịch sử khám và ghi chú sau buổi khám  
- 👪 Thêm người thân (Caregiver) cùng tham gia buổi khám  

---

## 📱 Tính năng chính
| Nhóm chức năng | Mô tả |
|----------------|-------|
| **Xác thực (Auth)** | Đăng ký, đăng nhập, phân quyền BN/BS |
| **Đặt lịch (Booking)** | Tìm bác sĩ, xem lịch trống, đặt – đổi – hủy lịch |
| **Phòng khám video** | Tham gia khám, bật/tắt mic/cam, chia sẻ tệp |
| **Chat trong phiên** | Nhắn tin, gửi ảnh/tệp, hiển thị thời gian thực |
| **Ghi chú sau khám** | BS ghi chú, BN xem lại và đặt lịch tái khám |
| **Thông báo** | Push Notification |
| **Giao diện thân thiện người cao tuổi** | Nút lớn, chữ to, thao tác đơn giản |

---

## 🧰 Công nghệ sử dụng
- **Flutter SDK**: 3.x  
- **Ngôn ngữ:** Dart  
- **Quản lý trạng thái:** Provider / BLoC  
- **Giao diện:** Material 3 + Custom Widgets  
- **Video Call:** WebRTC SDK (Agora)  
- **API:** Kết nối với backend NestJS qua REST API  
- **Env Config:** `flutter_dotenv` để đọc file `.env`  
- **Lưu trữ:** SharedPreferences / Hive (local data)  

---

## ⚙️ Cài đặt & Chạy ứng dụng

### 1️⃣ Cài đặt môi trường
- Cài [Flutter SDK](https://docs.flutter.dev/get-started/install)  
- Cài Android Studio hoặc VS Code (kèm plugin Flutter)  
- Đảm bảo emulator / thiết bị thật sẵn sàng

### 2️⃣ Cấu hình `.env`
Tạo file `.env` ở thư mục `frontend/`:
```env
API_BASE_URL=http://localhost:3000
VIDEO_APP_ID=your_app_id
VIDEO_APP_SECRET=your_secret
