import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../models/appointment.dart';
import '../../services/appointment_service.dart';
import '../video/video_room_screen.dart';
import '../../screens/chat_screen.dart';
import '../notes/notes_screen.dart';

class DoctorHomeScreen extends StatefulWidget {
  final UserProfile user;
  const DoctorHomeScreen({super.key, required this.user});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  final List<_DoctorAppt> _items = <_DoctorAppt>[];
  bool _loading = true;
  String _filter = 'ALL'; // ALL | UNPAID | UPCOMING | COMPLETED

  int get _doctorId => int.tryParse(widget.user.id.toString()) ?? 0;

  @override
  void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await AppointmentService().listMine(
        role: 'doctor',
        userId: _doctorId,
      );
      if (!mounted) return;
      _items
        ..clear()
        ..addAll(list.map((a) => _DoctorAppt(
              appt: a,
              patientName: 'Ẩn danh',
              status: a.status,
            )));
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Không tải được lịch: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final filtered = _items.where((e) {
      switch (_filter) {
        case 'UNPAID':
          return e.appt.paymentStatus != 'PAID';
        case 'UPCOMING':
          return e.appt.status == 'PENDING' || e.appt.status == 'CONFIRMED';
        case 'COMPLETED':
          return e.appt.status == 'COMPLETED';
        default:
          return true;
      }
    }).toList()
      ..sort((a, b) => a.appt.time.compareTo(b.appt.time));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: Container(
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
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text('Bác sĩ · ${widget.user.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
            centerTitle: true,
            actions: [
              IconButton(
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh, size: 28),
                tooltip: 'Tải lại',
              ),
            ],
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
              children: [
                Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Material(
                          elevation: 4,
                          shape: const CircleBorder(),
                          child: CircleAvatar(
                            radius: 32,
                            backgroundColor: const Color(0xFFE3F2FD),
                            child: Icon(Icons.medical_information, color: cs.primary, size: 32),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.user.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF222B45))),
                                const SizedBox(height: 6),
                                Text('Bác sĩ',
                                    style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600, fontSize: 15)),
                              ]),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    _chip('ALL', 'Tất cả'),
                    _chip('UPCOMING', 'Sắp tới'),
                    _chip('UNPAID', 'Chưa thanh toán'),
                    _chip('COMPLETED', 'Đã xong'),
                  ],
                ),
                const SizedBox(height: 12),
                if (filtered.isEmpty)
                  _empty(cs)
                else
                  ...filtered.map((e) => _DoctorApptCard(
  item: e,
  userName: widget.user.name,
  userId: widget.user.id.toString(),
  onAction: (updated) => setState(() {
    final idx = _items.indexWhere((x) => x.appt.id == updated.appt.id);
    if (idx >= 0) _items[idx] = updated;
  }),
                        onComplete: () async {
                          debugPrint('[APPT] Xác nhận/hủy: raw id = \'${e.appt.id}\'');
                          final intId = int.tryParse(e.appt.id) ?? -1;
                          debugPrint('[APPT] intId = $intId');
                          if (intId <= 0) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('ID cuộc hẹn không hợp lệ: ${e.appt.id} (intId=$intId)'),
                              ),
                            );
                            return;
                          }
                          try {
                            await AppointmentService()
                                .updateStatus(id: intId, status: 'COMPLETED');
                            if (!context.mounted) return;
                            // Sau khi xác nhận/hủy, reload lại danh sách lịch hẹn từ backend
                            await _load();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Đã đánh dấu hoàn thành.')),
                            );
                          } catch (err) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Cập nhật thất bại: $err')),
                            );
                          }
                        },
                      )),
                const SizedBox(height: 80),
              ],
            ),
    );
  }

  Widget _chip(String key, String label) {
    final cs = Theme.of(context).colorScheme;
    final selected = _filter == key;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ChoiceChip(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: selected ? Colors.white : cs.primary,
              letterSpacing: 0.2,
            ),
          ),
        ),
        selected: selected,
        showCheckmark: false,
        selectedColor: cs.primary,
        backgroundColor: cs.surface,
        side: BorderSide(color: selected ? cs.primary : cs.outlineVariant, width: 2),
        elevation: selected ? 4 : 0,
        pressElevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        onSelected: (_) => setState(() => _filter = key),
      ),
    );
  }

  Widget _empty(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(children: [
        Icon(Icons.event_busy, size: 36, color: cs.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text('Chưa có lịch hẹn phù hợp bộ lọc.',
              style: TextStyle(color: cs.onSurfaceVariant)),
        ),
      ]),
    );
  }
}

class _DoctorAppt {
  final Appointment appt;
  final String patientName;
  final String status; // UPCOMING | COMPLETED
  const _DoctorAppt(
      {required this.appt, required this.patientName, required this.status});

  _DoctorAppt copyWith({Appointment? appt, String? patientName, String? status}) =>
      _DoctorAppt(
        appt: appt ?? this.appt,
        patientName: patientName ?? this.patientName,
        status: status ?? this.status,
      );
}

class _DoctorApptCard extends StatelessWidget {
  final _DoctorAppt item;
  final void Function(_DoctorAppt updated) onAction;
  final VoidCallback onComplete;
  final String userName;
  final String userId;
const _DoctorApptCard({
    required this.item,
    required this.userName,
    required this.userId, // Thêm dòng này
    required this.onAction,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final a = item.appt;
    final paid = a.paymentStatus == 'PAID';
    final status = a.status;
  debugPrint('[APPT][CARD] id=${a.id}, status=$status');
  final isPending = status == 'PENDING';
  final isConfirmed = status == 'CONFIRMED';
  final isCompleted = status == 'COMPLETED';
    String timeStr = '${a.time.day.toString().padLeft(2, '0')}/${a.time.month.toString().padLeft(2, '0')}/${a.time.year} '
      '${a.time.hour.toString().padLeft(2, '0')}:${a.time.minute.toString().padLeft(2, '0')}';

    return Material(
      elevation: 5,
      borderRadius: BorderRadius.circular(24),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Material(
                elevation: 2,
                shape: const CircleBorder(),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFE3F2FD),
                  child: Text(item.patientName.characters.first.toUpperCase(),
                      style: const TextStyle(
                          color: Color(0xFF2196F3), fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.patientName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF222B45))),
                      const SizedBox(height: 2),
                      Text(timeStr,
                          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w500)),
                    ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: (paid ? Colors.green : Colors.orange).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                      color: paid ? Colors.green : Colors.orange, width: 2),
                ),
                child: Row(children: [
                  Icon(paid ? Icons.check_circle : Icons.schedule,
                      size: 18,
                      color: paid ? Colors.green : Colors.orange),
                  const SizedBox(width: 7),
                  Text(
                    paid ? 'ĐÃ THANH TOÁN' : 'CHƯA THANH TOÁN',
                    style: TextStyle(
                      fontSize: 13,
                      color: paid
                          ? Colors.green.shade800
                          : Colors.orange.shade800,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ]),
              ),
            ]),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  isCompleted ? Icons.verified_outlined : isConfirmed ? Icons.check_circle_outline : Icons.timelapse,
                  size: 22, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  isCompleted
                      ? 'ĐÃ HOÀN THÀNH'
                      : isConfirmed
                          ? 'ĐÃ XÁC NHẬN'
                          : 'CHỜ XÁC NHẬN',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: isCompleted
                        ? Colors.green
                        : isConfirmed
                            ? Colors.blue
                            : Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(spacing: 12, runSpacing: 12, children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.videocam_outlined),
                label: const Text('Bắt đầu khám', style: TextStyle(fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  textStyle: const TextStyle(fontSize: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: isCompleted
                    ? null
                    : () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => VideoRoomScreen(
                            channelName: item.appt.id.toString(),
                          uid: int.tryParse(item.appt.doctor.id) ?? 0,
                          ),
                        ));
                      },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.chat_outlined),
                label: const Text('Nhắn bệnh nhân', style: TextStyle(fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  textStyle: const TextStyle(fontSize: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChatScreen(
        roomId: item.appt.id,
  senderId: userId.toString(),
        senderName: userName,
      ),
    ));
  },
),
              OutlinedButton.icon(
                icon: const Icon(Icons.description_outlined),
                label: const Text('Ghi chú ca khám', style: TextStyle(fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  textStyle: const TextStyle(fontSize: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const NotesScreen()));
                },
              ),
              if (isPending)
                FilledButton.icon(
                  icon: const Icon(Icons.done_all),
                  label: const Text('Đánh dấu hoàn thành', style: TextStyle(fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    textStyle: const TextStyle(fontSize: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: onComplete,
                ),
            ]),
          ],
        ),
      ),
    );
  }
}
