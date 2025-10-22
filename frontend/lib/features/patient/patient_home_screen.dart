import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../app_config.dart';
import '../../services/doctor_service.dart';
import '../booking/book_appointment_screen.dart';
import '../video/video_room_screen.dart';
import '../../screens/chat_screen.dart';

/// Home UI for PATIENT – built to look like the provided screenshot.
/// Only includes features that are in your proposal: Booking doctor, Chat,
/// Video call, and Health profile/Notes. Everything else is omitted.
class PatientHomeScreen extends StatefulWidget {
  final UserProfile user;
  const PatientHomeScreen({super.key, required this.user});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {

  List<DoctorBrief> _doctors = const [];
  bool _loadingDoctors = true;
  String? _selectedSpecialty;
  List<String> _specialties = [];

  int get _patientId => int.tryParse(widget.user.id.toString()) ?? 0;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  // Lấy danh sách chuyên khoa từ danh sách bác sĩ
  void _extractSpecialties(List<DoctorBrief> doctors) {
    final specs = doctors.map((e) => e.specialty ?? '').where((s) => s.isNotEmpty).toSet().toList();
    specs.sort();
    setState(() => _specialties = specs);
  }

  Future<void> _loadDoctors() async {
    setState(() => _loadingDoctors = true);
    try {
      final data = await DoctorService().listDoctors(specialty: _selectedSpecialty);
      if (!mounted) return;
      setState(() => _doctors = data);
      _extractSpecialties(data);
    } catch (_) {
      if (!mounted) return;
      setState(() => _doctors = const []);
    } finally {
      if (!mounted) return;
      setState(() => _loadingDoctors = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Header(userName: widget.user.name)),
            // Bộ lọc chuyên khoa hiện đại
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    const Text('Chuyên khoa:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _specialties.isEmpty
                          ? const Text('Không có chuyên khoa', style: TextStyle(color: Colors.grey))
                          : DropdownButtonFormField<String>(
                              value: _selectedSpecialty,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              hint: const Text('Chọn chuyên khoa', style: TextStyle(fontSize: 15)),
                              items: [
                                const DropdownMenuItem<String>(value: null, child: Text('Tất cả chuyên khoa')),
                                ..._specialties.map((s) => DropdownMenuItem<String>(value: s, child: Text(s))),
                              ],
                              onChanged: (val) {
                                setState(() => _selectedSpecialty = val);
                                _loadDoctors();
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
            // Doctor carousel
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 8),
                child: Row(
                  children: [
                    const Text('Bác sĩ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 6),
                    const Text(' *', style: TextStyle(color: Color(0xFF2D8CFF), fontWeight: FontWeight.w800)),
                    const Spacer(),
                    TextButton(onPressed: () {}, child: const Text('Xem tất cả')),
                  ],
                ),
              ),
            ),
            if (_loadingDoctors)
              const SliverToBoxAdapter(
                child: SizedBox(height: 96, child: Center(child: CircularProgressIndicator())),
              )
            else
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 96,
                  child: _doctors.isEmpty
                      ? Center(child: Text('Không có bác sĩ nào.', style: TextStyle(fontSize: 16, color: Colors.grey)))
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          itemCount: _doctors.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 16),
                          itemBuilder: (context, i) => _DoctorChip(
                            doctor: _doctors[i],
                            onTap: () async {
                              final appt = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BookAppointmentScreenNew(
                                    patientId: _patientId,
                                  ),
                                ),
                              );
                              if (!mounted) return;
                              if (appt != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Đã đặt lịch với ${_doctors[i].name}.')),
                                );
                              }
                            },
                          ),
                        ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            // Feature grid with only 3 features
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _FeatureGrid(
                  items: [
                    FeatureItem(
                      icon: Icons.medical_services,
                      label: 'Đặt lịch',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookAppointmentScreenNew(patientId: _patientId),
                          ),
                        );
                      },
                    ),
                    FeatureItem(
                      icon: Icons.chat,
                      label: 'Chat với bác sĩ',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              roomId: 'general_patient_chat',
                              senderId: 'patient',
                              senderName: widget.user.name.trim().isNotEmpty ? widget.user.name : 'Bệnh nhân',
                            ),
                          ),
                        );
                      },
                    ),
                    FeatureItem(
                      icon: Icons.video_call,
                      label: 'Gọi video với bác sĩ',
                      onTap: () async {
                        // Sau khi đặt lịch, lấy appointment id từ kết quả đặt lịch hoặc danh sách lịch hẹn
                        final appt = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookAppointmentScreenNew(
                              patientId: _patientId,
                            ),
                          ),
                        );
                        if (!mounted || appt == null) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoRoomScreen(
                              channelName: appt.id.toString(),
                              uid: int.tryParse(widget.user.id) ?? 0,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String userName;
  const _Header({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 180,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2196F3), Color(0xFF21CBF3)],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x332196F3),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Material(
                elevation: 6,
                shape: const CircleBorder(),
                color: Colors.transparent,
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white.withOpacity(0.18),
                  child: Text(
                    _initials(userName),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: 1.2),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Chào mừng trở lại!', style: TextStyle(color: Colors.white.withOpacity(0.92), fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(
                      userName,
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {},
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      const Icon(Icons.notifications_none, color: Colors.white, size: 32),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.shade400,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.redAccent.withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                          child: const Text(
                            '3',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _initials(String fullName) {
    final parts = fullName.trim().split(RegExp(r"\s+"));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.characters.take(2).toString().toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }
}

class _FeatureGrid extends StatelessWidget {
  final List<FeatureItem> items;
  const _FeatureGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(24),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          height: 140, // Đảm bảo không bị tràn, vừa đủ cho 2 dòng icon và text
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 18,
              crossAxisSpacing: 18,
              childAspectRatio: .95,
            ),
            itemCount: items.length,
            itemBuilder: (context, i) => _FeatureTile(item: items[i]),
          ),
        ),
      ),
    );
  }
}

class FeatureItem {
  final IconData icon;
  final String label; // allow line breaks with \n
  final VoidCallback onTap;
  const FeatureItem({required this.icon, required this.label, required this.onTap});
}

class _FeatureTile extends StatelessWidget {
  final FeatureItem item;
  const _FeatureTile({required this.item});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(20),
      splashColor: const Color(0xFF2196F3).withOpacity(0.12),
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2196F3).withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(item.icon, size: 32, color: const Color(0xFF2196F3)),
          ),
          const SizedBox(height: 10),
          Text(
            item.label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF222B45)),
          ),
        ],
      ),
    );
  }
}

class _DoctorChip extends StatelessWidget {
  final DoctorBrief doctor;
  final VoidCallback onTap;
  const _DoctorChip({required this.doctor, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final avatarUrl = (doctor.avatar != null && doctor.avatar!.isNotEmpty)
        ? (doctor.avatar!.startsWith('/')
            ? '${AppConfig.apiBase}${doctor.avatar}'
            : doctor.avatar!)
        : null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          elevation: 4,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(48),
            child: CircleAvatar(
              radius: 36,
              backgroundColor: const Color(0xFFE3F2FD),
              backgroundImage: (avatarUrl != null)
                  ? NetworkImage(avatarUrl)
                  : null,
              child: (avatarUrl == null)
                  ? Text(
                      doctor.name.characters.first.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2196F3), fontSize: 22),
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 100,
          alignment: Alignment.center,
          child: Text(
            doctor.name,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF222B45)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}