// lib/services/appointment_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../app_config.dart';
import '../models/appointment.dart';
import '../models/appointment_mapper.dart';

class AppointmentService {
  final String base = AppConfig.apiBase;

  /// Lấy slot trống của bác sĩ theo ngày
  Future<List<DateTime>> getDoctorSlots({
    required int doctorId,
    required DateTime date,
  }) async {
    // GỬI CHỈ NGÀY: yyyy-MM-dd
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    final url = Uri.parse('$base/appointments/slots?doctorId=$doctorId&date=$dateStr');

    final res = await http.get(url);
    if (res.statusCode == 200) {
      final arr = jsonDecode(res.body) as List;
      // BE trả "yyyy-MM-ddTHH:mm:ss" (không timezone) → parse local
      return arr.map<DateTime>((e) => DateTime.parse(e.toString())).toList();
    }
    throw Exception('getDoctorSlots failed: ${res.statusCode} ${res.body}');
  }

  /// Tạo lịch hẹn mới
  /// Body khớp backend: { patientId, doctorId, appointmentTime, note?, amount?, triageId? }
  Future<Appointment> create({
    required int patientId,
    required int doctorId,
    required DateTime appointmentTime,
    String? note,
    int? amount,
    String? triageId,
  }) async {
    final url = Uri.parse('$base/appointments');

    // GỬI LOCAL ISO (KHÔNG toUtc()) để tránh lệch múi giờ khi BE so sánh với "now"
    final atIso = appointmentTime.toIso8601String();

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'patientId': patientId,
        'doctorId': doctorId,
        'appointmentTime': atIso,
        if (note != null && note.isNotEmpty) 'note': note,
        if (amount != null) 'amount': amount,
        if (triageId != null) 'triageId': triageId,
      }),
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return mapAppointmentFromBackend(data);
    }
    throw Exception('Create appt failed: ${res.statusCode} ${res.body}');
  }

  /// Lấy danh sách lịch hẹn của tôi
  /// GET /appointments/mine?role=patient|doctor&userId=...&status=...
  Future<List<Appointment>> listMine({
    required String role, // 'patient' | 'doctor'
    required int userId,
    String? status,
  }) async {
    final q = Uri(queryParameters: {
      'role': role,
      'userId': '$userId',
      if (status != null && status.isNotEmpty) 'status': status,
    }).query;

    final url = Uri.parse('$base/appointments/mine?$q');
    final res = await http.get(url);

    if (res.statusCode == 200) {
      final arr = jsonDecode(res.body) as List;
      return arr
          .map((e) => mapAppointmentFromBackend(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('List appt failed: ${res.statusCode} ${res.body}');
  }

  /// Cập nhật trạng thái lịch hẹn
  /// PATCH /appointments/:id/status  { status, reason? }
  Future<Appointment> updateStatus({
    required int id,
    required String status, // CONFIRMED | REJECTED | CANCELLED | COMPLETED | NO_SHOW
    String? reason,
  }) async {
    final url = Uri.parse('$base/appointments/$id/status');
    final res = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'status': status,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      }),
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return mapAppointmentFromBackend(data);
    }
    throw Exception('Update status failed: ${res.statusCode} ${res.body}');
  }
}
