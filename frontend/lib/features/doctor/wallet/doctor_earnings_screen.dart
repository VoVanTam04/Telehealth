import 'package:flutter/material.dart';
import '../../../models/user_profile.dart';

class DoctorEarningsScreen extends StatelessWidget {
  final UserProfile user;
  const DoctorEarningsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // TODO: Lấy dữ liệu doanh thu từ backend
    final totalMonth = 0;
    final completed = 0;
    final pending = 0;
    final payouts = const <({String a, String b, String c, String d})>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Doanh thu')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            Expanded(child: _StatCard(title: 'Tháng này', value: '${_fmt(totalMonth)} đ', color: cs.primary)),
            const SizedBox(width: 10),
            Expanded(child: _StatCard(title: 'Đã khám', value: '$completed ca', color: Colors.green)),
            const SizedBox(width: 10),
            Expanded(child: _StatCard(title: 'Chờ thanh toán', value: '$pending ca', color: Colors.orange)),
          ]),
          const SizedBox(height: 16),
          Text('Giao dịch gần đây', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (payouts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text('Chưa có giao dịch nào.', style: TextStyle(color: cs.onSurfaceVariant)),
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  String _fmt(int v){
    final s = v.toString();
    final b = StringBuffer();
    for (int i=0;i<s.length;i++){
      final r = s.length - i;
      b.write(s[i]);
      if (r>1 && r%3==1) b.write('.');
    }
    return b.toString();
  }

}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: color)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ]),
    );
  }
}
