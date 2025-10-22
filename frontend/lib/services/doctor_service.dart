// lib/services/doctor_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../app_config.dart';

class DoctorBrief {
  final int id;
  final String name;
  final String? specialty;
  final int? fee;
  final String? bank;
  final String? bankAccount;
  final String? city;
  final String? email;
  final String? avatar;

  DoctorBrief({
    required this.id, required this.name,
    this.specialty, this.fee, this.bank, this.bankAccount, this.city, this.email, this.avatar,
  });

  factory DoctorBrief.fromJson(Map<String, dynamic> j) {
    // Debug log to check API response
    print('[DoctorBrief.fromJson] $j');
    return DoctorBrief(
      id: j['id'] is int ? j['id'] : int.tryParse(j['id'].toString()) ?? 0,
      name: j['name'] ?? j['doctorName'] ?? 'Bác sĩ',
      specialty: j['specialty'] ?? j['doctorSpecialty'],
      fee: j['fee'] ?? j['doctorFee'],
      bank: j['bank'] ?? j['doctorBank'],
      bankAccount: j['bankAccount'] ?? j['doctorBankAccount'],
      city: j['city'] ?? j['doctorCity'],
      email: j['email'],
      avatar: j['avatar'],
    );
  }
}

class DoctorService {
  final String base = AppConfig.apiBase;

  Future<List<DoctorBrief>> listDoctors({String? city, String? specialty}) async {
    // Gọi API /users?role=doctor&city=...&specialty=...
    final qp = Uri(queryParameters: {
      'role': 'doctor',
      if (city != null && city.isNotEmpty) 'city': city,
      if (specialty != null && specialty.isNotEmpty) 'specialty': specialty,
    }).query;
    final url = Uri.parse('$base/users${qp.isNotEmpty ? '?$qp' : ''}');
    final res = await http.get(url);
    print('[DoctorService.listDoctors] response: ${res.body}');
    if (res.statusCode == 200) {
      // Nếu backend trả về dạng {data, meta}
      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded['data'] is List) {
        return (decoded['data'] as List).map((e) => DoctorBrief.fromJson(e)).toList();
      }
      if (decoded is List) {
        return decoded.map((e) => DoctorBrief.fromJson(e)).toList();
      }
      return [];
    }
    throw Exception('listDoctors thất bại: ${res.statusCode} ${res.body}');
  }

  Future<DoctorBrief> getDoctor(int id) async {
    final res = await http.get(Uri.parse('$base/users/$id'));
    if (res.statusCode == 200) {
      return DoctorBrief.fromJson(jsonDecode(res.body));
    }
    throw Exception('getDoctor failed: ${res.statusCode} ${res.body}');
  }

  Future<DoctorBrief> updateProfile({
    required int id,
    String? specialty,
    int? fee,
    String? bank,
    String? bankAccount,
    String? city,
  }) async {
    final res = await http.patch(
      Uri.parse('$base/users/$id/profile'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        if (specialty != null) 'specialty': specialty,
        if (fee != null) 'fee': fee,
        if (bank != null) 'bank': bank,
        if (bankAccount != null) 'bankAccount': bankAccount,
        if (city != null) 'city': city,
      }),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return DoctorBrief.fromJson(jsonDecode(res.body));
    }
    throw Exception('updateProfile failed: ${res.statusCode} ${res.body}');
  }
  
}
