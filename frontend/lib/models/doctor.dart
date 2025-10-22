import 'package:vietqr_core/vietqr_core.dart';

class Doctor {
  final String id, name, specialty;
  final int fee; // VND - phí khám cơ bản
  // 👇 Thêm thông tin thanh toán cho từng bác sĩ
  final SupportedBank bank;
  final String account;
  final String city; // ≤ 15 ký tự, ví dụ: 'TP HCM', 'Hanoi'

  const Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.fee,
    required this.bank,
    required this.account,
    this.city = 'TP HCM',
  });
}