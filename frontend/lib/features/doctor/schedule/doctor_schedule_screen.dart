import 'package:flutter/material.dart';

import '../../../models/user_profile.dart';
import '../../../models/appointment.dart';
import '../../../services/appointment_service.dart';
import '../../video/video_room_screen.dart';
import 'package:telehealth/screens/chat_screen.dart';
import '../../notes/notes_screen.dart';

class DoctorScheduleScreen extends StatefulWidget {
  final UserProfile user;
  const DoctorScheduleScreen({super.key, required this.user});

  @override
  State<DoctorScheduleScreen> createState() => _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends State<DoctorScheduleScreen> {
  final List<_DoctorAppt> _items = <_DoctorAppt>[];
  bool _loading = true;
  String _filter = 'ALL'; // ALL | UPCOMING | UNPAID | COMPLETED

  int get _doctorId => int.tryParse(widget.user.id.toString()) ?? 0;

  @override
  void initState() {
    super.initState();
    _load();
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
              patientName: 'Bệnh nhân',
              status: a.status,
            )));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Không tải được lịch: $e')));
    } finally {
      if (context.mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final list = _items.where((e) {
      switch (_filter) {
        case 'UPCOMING':
          return e.status == 'PENDING' || e.status == 'CONFIRMED';
        case 'UNPAID':
          return e.appt.paymentStatus != 'PAID';
        case 'COMPLETED':
          return e.status == 'COMPLETED';
        default:
          return true;
      }
    }).toList()
      ..sort((a, b) => a.appt.time.compareTo(b.appt.time));

    return Scaffold(
      appBar: AppBar(title: const Text('Lịch khám'), actions: [
        IconButton(
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh),
          tooltip: 'Tải lại',
        )
      ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _DoctorHeader(
                  name: widget.user.name,
                  specialty: 'Bác sĩ', // nếu có chuyên khoa thực, thay tại đây
                ),
                const SizedBox(height: 12),
                Wrap(spacing: 8, children: [
                  _chip('ALL', 'Tất cả'),
                  _chip('UPCOMING', 'Sắp tới'),
                  _chip('UNPAID', 'Chưa thanh toán'),
                  _chip('COMPLETED', 'Đã xong'),
                ]),
                const SizedBox(height: 12),
                if (list.isEmpty)
                  _empty(cs)
                else
                  ...list.map((e) => _ApptCard(
                        item: e,
                        onUpdate: (u) {
                          final i =
                              _items.indexWhere((x) => x.appt.id == u.appt.id);
                          if (i >= 0) setState(() => _items[i] = u);
                        },
                        onComplete: () async {
                          // BE yêu cầu id:int; FE id:String => chuyển đổi an toàn
                          final intId = int.tryParse(e.appt.id) ?? -1;
                          if (intId <= 0) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('ID cuộc hẹn không hợp lệ')),
                            );
                            return;
                          }
                          try {
                            await AppointmentService().updateStatus(
                                id: intId, status: 'COMPLETED');
                            if (!context.mounted) return;
                            setState(() {
                              final i = _items
                                  .indexWhere((x) => x.appt.id == e.appt.id);
                              if (i >= 0) {
                                _items[i] =
                                    _items[i].copyWith(status: 'COMPLETED');
                              }
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Đã đánh dấu hoàn thành.')),
                            );
                          } catch (err) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Cập nhật thất bại: $err')),
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

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: selected ? cs.onPrimary : cs.onSurface,
        ),
      ),
      selected: selected,
      showCheckmark: false,
      selectedColor: cs.primary,
      backgroundColor: cs.surface,
      side: BorderSide(color: selected ? cs.primary : cs.outlineVariant),
      onSelected: (_) => setState(() => _filter = key),
    );
  }

  Widget _empty(ColorScheme cs) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant)),
        child: Row(children: [
          Icon(Icons.event_busy, size: 36, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
              child: Text('Chưa có lịch phù hợp bộ lọc.',
                  style: TextStyle(color: cs.onSurfaceVariant))),
        ]),
      );
}

class _DoctorHeader extends StatelessWidget {
  final String name;
  final String specialty;
  const _DoctorHeader({required this.name, required this.specialty});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primaryContainer, cs.secondaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: cs.onPrimaryContainer.withValues(alpha: .08),
          child: Icon(Icons.medical_information, color: cs.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
            Text(specialty, style: TextStyle(color: cs.onSurfaceVariant)),
          ]),
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
          status: status ?? this.status);
}

class _ApptCard extends StatelessWidget {
  final _DoctorAppt item;
  final void Function(_DoctorAppt updated) onUpdate;
  final VoidCallback onComplete;
  const _ApptCard(
      {required this.item, required this.onUpdate, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final a = item.appt;
    final paid = a.paymentStatus == 'PAID';
    final isCompleted = item.status == 'COMPLETED';
    final isConfirmed = item.status == 'CONFIRMED';
    final isPending = item.status == 'PENDING';

    Future<void> _confirmAppt(BuildContext context) async {
      final intId = int.tryParse(a.id) ?? -1;
      if (intId <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID cuộc hẹn không hợp lệ')));
        return;
      }
      try {
        final updated = await AppointmentService().updateStatus(id: intId, status: 'CONFIRMED');
        onUpdate(item.copyWith(appt: updated, status: 'CONFIRMED'));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xác nhận lịch hẹn.')));
      } catch (err) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xác nhận thất bại: $err')));
      }
    }

    Future<void> _cancelAppt(BuildContext context) async {
      final intId = int.tryParse(a.id) ?? -1;
      if (intId <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID cuộc hẹn không hợp lệ')));
        return;
      }
      try {
        final updated = await AppointmentService().updateStatus(id: intId, status: 'CANCELLED');
        onUpdate(item.copyWith(appt: updated, status: 'CANCELLED'));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã hủy lịch hẹn.')));
      } catch (err) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hủy lịch thất bại: $err')));
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: cs.secondaryContainer,
              child: Text(item.patientName.characters.first.toUpperCase(),
                  style: TextStyle(
                      color: cs.onSecondaryContainer,
                      fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.patientName,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(
                      '${a.time.day.toString().padLeft(2, '0')}/'
                      '${a.time.month.toString().padLeft(2, '0')}/'
                      '${a.time.year} '
                      '${a.time.hour.toString().padLeft(2, '0')}:${a.time.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                  ]),
            ),
            _statusPill(paid, cs),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Icon(
              isCompleted
                  ? Icons.verified_outlined
                  : isConfirmed
                      ? Icons.check_circle_outline
                      : Icons.timelapse,
              size: 18,
              color: isCompleted
                  ? Colors.green
                  : isConfirmed
                      ? Colors.blue
                      : cs.primary,
            ),
            const SizedBox(width: 6),
            Text(
              isCompleted
                  ? 'ĐÃ HOÀN THÀNH'
                  : isConfirmed
                      ? 'ĐÃ XÁC NHẬN'
                      : isPending
                          ? 'CHỜ XÁC NHẬN'
                          : item.status,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isCompleted
                    ? Colors.green
                    : isConfirmed
                        ? Colors.blue
                        : cs.primary,
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton.tonalIcon(
              icon: const Icon(Icons.videocam_outlined),
              label: const Text('Bắt đầu khám'),
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
            if (isConfirmed)
              OutlinedButton.icon(
                icon: const Icon(Icons.chat_outlined),
                label: const Text('Nhắn bệnh nhân'),
                onPressed: () {
                  final doctorId = item.appt.doctor.id;
                  final doctorName = item.appt.doctor.name;
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      roomId: item.appt.id,
                      senderId: doctorId.toString(),
                      senderName: doctorName,
                    ),
                  ));
                },
              ),
            OutlinedButton.icon(
              icon: const Icon(Icons.description_outlined),
              label: const Text('Ghi chú ca khám'),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const NotesScreen()));
              },
            ),
            if (!isCompleted)
              FilledButton.icon(
                icon: const Icon(Icons.done_all),
                label: const Text('Đánh dấu hoàn thành'),
                onPressed: onComplete,
              ),
            if (isPending) ...[
              FilledButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Xác nhận lịch'),
                onPressed: () => _confirmAppt(context),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Hủy lịch'),
                onPressed: () => _cancelAppt(context),
              ),
            ],
          ]),
        ]),
      ),
    );
  }

  Widget _statusPill(bool paid, ColorScheme cs) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: (paid ? Colors.green : Colors.orange).withValues(alpha: .12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: paid ? Colors.green : Colors.orange),
        ),
        child: Text(
          paid ? 'ĐÃ THANH TOÁN' : 'CHƯA THANH TOÁN',
          style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: paid ? Colors.green.shade800 : Colors.orange.shade800,
          ),
        ),
      );
}
