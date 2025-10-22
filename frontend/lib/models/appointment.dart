import 'doctor.dart';

class Appointment {
  final String id;
  final Doctor doctor;
  final DateTime time;
  final String patientNote;
  final int? amount;          // null = QR động (nhập tiền khi quét)
  final String status;        // 'PENDING' | 'CONFIRMED' | ...
  final String paymentStatus; // 'UNPAID' | 'PAID'
  final String? paymentRef;   // mã giao dịch (tuỳ chọn)

  const Appointment({
    required this.id,
    required this.doctor,
    required this.time,
    required this.patientNote,
    this.amount,
    this.status = 'PENDING',
    this.paymentStatus = 'UNPAID',
    this.paymentRef,
  });

  Appointment copyWith({
    Doctor? doctor,
    DateTime? time,
    String? patientNote,
    int? amount,
    String? status,
    String? paymentStatus,
    String? paymentRef,
  }) {
    return Appointment(
      id: id,
      doctor: doctor ?? this.doctor,
      time: time ?? this.time,
      patientNote: patientNote ?? this.patientNote,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentRef: paymentRef ?? this.paymentRef,
    );
  }
}