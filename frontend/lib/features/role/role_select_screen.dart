import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../patient/patient_home_screen.dart';
import '../doctor/doctor_home_screen.dart';

/// Placeholder user cho BỆNH NHÂN khi bạn chưa truyền user thật từ login.
/// Khi đã có user thật, chỉ cần thay `_placeholderPatient` bằng user đó.
final _placeholderPatient = UserProfile(
  id: 'temp',
  name: 'Bạn',
  role: 'patient',
  email: '',
  avatar: null,
);

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Telehealth')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primaryContainer, cs.secondaryContainer],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: cs.onPrimaryContainer.withOpacity(.08),
                  child: Icon(Icons.health_and_safety, color: cs.primary, size: 30),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Telehealth',
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Đặt lịch → Thanh toán VietQR → Khám online',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _RoleTile(
                  icon: Icons.person_outline,
                  title: 'Bệnh nhân',
                  subtitle: 'Đặt lịch',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      // ⬇️ dùng placeholder thay cho mockPatient
                      builder: (_) => PatientHomeScreen(user: _placeholderPatient),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RoleTile(
                  icon: Icons.medical_information_outlined,
                  title: 'Bác sĩ',
                  subtitle: 'Quản lý ca khám',
                  outlined: true,
                  onTap: () {
                    // ✅ Demo doctor user (sau này thay bằng user thật sau login)
                    final demoDoctor = UserProfile(
                      id: 'u_doc_demo',
                      name: 'Bác sĩ Demo',
                      role: 'doctor', // giữ chữ thường cho nhất quán
                      email: 'demo@gmail.com',
                      avatar: null,
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DoctorHomeScreen(user: demoDoctor)),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool outlined;

  const _RoleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.outlined = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: outlined ? cs.surface : cs.primaryContainer,
          borderRadius: BorderRadius.circular(16),
          border: outlined ? Border.all(color: cs.outlineVariant) : null,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: cs.primary.withOpacity(.08),
              child: Icon(icon, color: cs.primary, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _BulletCard extends StatelessWidget {
  final String title;
  final List<String> bullets;
  const _BulletCard({required this.title, required this.bullets, super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            ...bullets.map(
              (t) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Icon(Icons.check_circle, size: 18, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(t)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
