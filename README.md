# 🩺 Telehealth – Hệ thống Dịch vụ Chăm sóc Sức khỏe Từ Xa

## 📖 Giới thiệu
Telehealth là nền tảng hỗ trợ **khám bệnh từ xa** giữa bác sĩ và bệnh nhân thông qua **ứng dụng di động (Flutter)** và **hệ thống quản lý backend (NestJS + SQL Server)**.

Chức năng chính:
- 📅 Đặt lịch hẹn khám trực tuyến  
- 🎥 Khám bệnh qua video (WebRTC / Video SDK)  
- 💬 Chat và gửi tệp (ảnh xét nghiệm, đơn thuốc)  
- 🩻 Ghi chú sau khám, lịch sử khám bệnh  
- 👪 Người thân (Caregiver) có thể tham dự buổi khám  
- 🔐 Bảo mật dữ liệu bằng JWT, RBAC, TLS, Audit log  

---

## 🧱 Kiến trúc thư mục
telehealth/
├── frontend/ # App Flutter cho BN/BS 
│ ├── lib/
│ ├── pubspec.yaml
│ └── README.md
│
├── backend/ # NestJS REST API + SQL Server
│ ├── src/
│ ├── package.json
│ ├── .env.example
│ └── README.md
│
└── README.md # Tệp mô tả tổng thể (file này)