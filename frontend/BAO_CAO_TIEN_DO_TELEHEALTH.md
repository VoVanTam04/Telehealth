# BÁO CÁO TỔNG HỢP TIẾN ĐỘ CHỨC NĂNG TELEHEALTH (theo proposal)

## 1. Chức năng đã có (theo code thực tế)

### Frontend (Flutter)
- **Tài khoản & hồ sơ (BN/BS):**
  - Đã có màn hình đăng nhập, đăng ký (`login_screen.dart`), đổi mật khẩu, cập nhật hồ sơ (`profile_screen.dart`, `change_password_screen.dart`).
- **Đặt lịch & nhắc lịch:**
  - Đã có màn hình đặt lịch, xem lịch sử, chi tiết lịch hẹn, xác nhận/hủy/đổi lịch (`book_appointment_screen.dart`, `appointments_screen.dart`, `appointment_detail_screen.dart`).
- **Phòng khám video:**
  - Đã có màn hình join phòng video, truyền tham số channelName/uid, gọi API lấy token (`video_room_screen.dart`).
- **Chat trong phiên & chia sẻ tệp:**
  - Đã có màn hình chat, gửi nhận tin nhắn, gửi file (cần kiểm tra thêm phần upload file thực tế).
- **Ghi chú sau khám:**
  - Đã có màn hình ghi chú, xem lại ghi chú sau khám (`notes_screen.dart`).
- **Dashboard vận hành:**
  - Chưa thấy file dashboard rõ ràng, có thể chưa hoàn thiện.
- **Elderly-Friendly UI:**
  - Một số màn hình có nút lớn, chưa thấy code hướng dẫn 30s/trợ lý gọi rõ ràng.
- **Caregiver Join:**
  - Chưa thấy rõ chức năng gửi link mời người thân join phòng.

### Backend (NestJS)
- **User/Auth:**
  - Đã có module, controller, service cho user, đăng nhập, đăng ký, đổi mật khẩu, RBAC cơ bản (`users.controller.ts`, `users.service.ts`, `users.module.ts`).
- **Appointment:**
  - Đã có module, controller, service cho đặt lịch, xác nhận, hủy, đổi lịch (`appointments.module.ts`, ...).
- **Video:**
  - Đã có controller cấp token video (Agora) (`agora.controller.ts`).
- **Mail/Notification:**
  - Đã có service gửi mail (mail.service.ts), chưa rõ đã có push/SMS.
- **Audit log, RBAC:**
  - Đã có RBAC cơ bản, chưa thấy rõ code audit log chi tiết.
- **Bảo mật:**
  - Đã cấu hình TLS, JWT, at-rest encryption (theo config), chưa thấy code kiểm thử bảo mật.
- **Chat & File:**
  - Chưa thấy rõ module chat realtime (WebSocket/Gateway), file upload đã có (avatar, xét nghiệm), cần kiểm tra thêm.
- **AI Triage:**
  - Chưa thấy module AI triage (pre-visit risk score).

## 2. Chức năng đang thiếu/chưa rõ
- AI sàng lọc nguy cơ trước khám (Triage)
- Caregiver Join (mời người thân join phòng)
- Dashboard vận hành (giám sát, chỉ số call)
- Audit log chi tiết, kiểm thử bảo mật, log chất lượng call
- Push/SMS notification
- Hướng dẫn 30s, trợ lý gọi cho người cao tuổi

## 3. Đánh giá tổng thể
- Các luồng cốt lõi (đăng nhập, đặt lịch, join video, chat, ghi chú) đã có đủ cơ bản.
- Một số chức năng nâng cao (AI triage, caregiver join, dashboard, audit log, push/SMS) chưa thấy hoặc chưa hoàn thiện.
- Bảo mật đã có cấu hình cơ bản, cần bổ sung kiểm thử và log chi tiết.

## 4. Đề xuất
- Bổ sung/hoàn thiện các chức năng còn thiếu theo proposal.
- Kiểm tra kỹ các luồng upload file, chat realtime, audit log, dashboard.
- Đánh giá lại UI/UX cho người cao tuổi, bổ sung hướng dẫn/trợ lý nếu cần.

---
Báo cáo này tổng hợp dựa trên code thực tế và proposal. Nếu cần chi tiết từng file hoặc checklist cụ thể, hãy yêu cầu thêm.