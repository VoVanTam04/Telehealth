import 'dart:convert';
import 'package:http/http.dart' as http;
import '../app_config.dart';

class TriageResult {
  final double riskScore;
  final String riskLabel; // "Thấp" | "Trung bình" | "Cao"
  final String? suggestion;
  final String triageId;
  final DateTime createdAt;

  TriageResult({
    required this.riskScore,
    required this.riskLabel,
    this.suggestion,
    required this.triageId,
    required this.createdAt,
  });

  factory TriageResult.fromJson(Map<String, dynamic> j) => TriageResult(
        riskScore: (j['risk_score'] as num).toDouble(),
        riskLabel: j['risk_label'] as String,
        suggestion: j['suggestion'] as String?,
        triageId: j['triage_id'] as String,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

class TriageService {
  final String apiBase;
  TriageService({String? apiBase}) : apiBase = apiBase ?? AppConfig.apiBase;

  Future<TriageResult> infer({
    required int age,
    required String gender, // 'male' | 'female' | 'other'
    String? history,
    required String symptoms,
  }) async {
    final uri = Uri.parse('$apiBase/api/triage/infer'); // BE: /api/triage/infer ? -> nếu có /api, cập nhật AppConfig.apiBase cho nhất quán
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'age': age,
        'gender': gender,
        'history': history,
        'symptoms': symptoms,
      }),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Triage failed: ${res.statusCode} ${res.body}');
    }
    return TriageResult.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}
