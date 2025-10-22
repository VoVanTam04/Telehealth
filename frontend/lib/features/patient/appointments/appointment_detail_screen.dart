import '../../../services/auth_service.dart';
import 'package:flutter/material.dart';
import '../../../models/appointment.dart';
import '../../payment/payment_screen.dart';
import '../../video/video_room_screen.dart';
import 'package:telehealth/screens/chat_screen.dart';
import '../../notes/notes_screen.dart';
import '../../../services/appointment_service.dart';

class AppointmentDetailScreen extends StatelessWidget {
  final Appointment appt;
  final String userName;
  final String userId;
  const AppointmentDetailScreen({super.key, required this.appt, required this.userName, required this.userId});

  void _cancelAppointment(BuildContext context) async {
    try {
      await AppointmentService().updateStatus(id: int.parse(appt.id), status: 'CANCELLED');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã hủy lịch hẹn.')));
      // Trả về true để màn appointments_screen biết cần reload lại danh sách
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hủy lịch thất bại: $e')));
    }
  }

  void _rescheduleAppointment(BuildContext context) async {
    // TODO: Hiển thị màn chọn lại thời gian, sau đó gọi API đổi lịch
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chức năng đổi lịch sẽ được bổ sung.')));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final paid = appt.paymentStatus=='PAID';
    final status = appt.status;
    Color statusColor;
    String statusText;
    switch (status) {
      case 'CONFIRMED':
        statusColor = Colors.green;
        statusText = 'Đã xác nhận';
        break;
      case 'PENDING':
        statusColor = Colors.orange;
        statusText = 'Chờ xác nhận';
        break;
      case 'CANCELLED':
        statusColor = Colors.red;
        statusText = 'Đã hủy';
        break;
      default:
        statusColor = Colors.grey;
        statusText = status;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết lịch hẹn')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Bác sĩ
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: cs.secondaryContainer,
                child: Text(appt.doctor.name.characters.first.toUpperCase(),
                  style: TextStyle(color: cs.onSecondaryContainer, fontWeight: FontWeight.w800)),
              ),
              title: Text(appt.doctor.name, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${appt.doctor.specialty}\n${appt.time}'),
                  const SizedBox(height: 4),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: statusColor),
                      ),
                      child: Text(statusText, style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: statusColor,
                      )),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (paid ? Colors.green : Colors.orange).withOpacity(.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: paid ? Colors.green : Colors.orange),
                      ),
                      child: Text(paid ? 'Đã thanh toán' : 'Chưa thanh toán', style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: paid ? Colors.green : Colors.orange,
                      )),
                    ),
                  ]),
                ],
              ),
              isThreeLine: true,
              trailing: Text('${appt.amount ?? appt.doctor.fee} đ', style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 12),

          // Pre-call checklist
          _SectionHeader(title: 'Chuẩn bị trước khi khám'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: const [
                _ChecklistRow(icon: Icons.videocam_outlined, text: 'Cho phép camera & micro'),
                _ChecklistRow(icon: Icons.wifi_tethering, text: 'Kết nối mạng ổn định (≥ 5 Mbps)'),
                _ChecklistRow(icon: Icons.light_mode_outlined, text: 'Môi trường đủ sáng/ít ồn'),
                _ChecklistRow(icon: Icons.description_outlined, text: 'Chuẩn bị đơn thuốc/kết quả xét nghiệm'),
              ]),
            ),
          ),
          const SizedBox(height: 12),

          _SectionHeader(title: 'Thao tác nhanh'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton.icon(
              icon: const Icon(Icons.videocam_outlined),
              label: const Text('Vào phòng khám'),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => VideoRoomScreen(
                    channelName: appt.id.toString(),
                    uid: int.tryParse(appt.doctor.id) ?? 0,
                  ),
                ));
              },
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.qr_code),
              label: const Text('Thanh toán VietQR'),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PaymentScreen(appt: appt)),
                );
                if (result != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã cập nhật trạng thái thanh toán.')),
                  );
                }
              },
            ),
            if (appt.status == 'CONFIRMED')
              OutlinedButton.icon(
                icon: const Icon(Icons.chat_outlined),
                label: const Text('Chat với bác sĩ'),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      roomId: appt.id,
                      senderId: userId,
                      senderName: userName.trim().isNotEmpty ? userName : 'Bệnh nhân',
                    ),
                  ));
                },
              ),
            OutlinedButton.icon(
              icon: const Icon(Icons.description_outlined),
              label: const Text('Ghi chú sau khám'),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotesScreen()));
              },
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.event_busy),
              label: const Text('Hủy lịch'),
              onPressed: () => _cancelAppointment(context),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.update),
              label: const Text('Đổi lịch'),
              onPressed: () => _rescheduleAppointment(context),
            ),
          ]),
          const SizedBox(height: 24),

          if (appt.patientNote.isNotEmpty) ...[
            _SectionHeader(title: 'Ghi chú khi đặt lịch'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(appt.patientNote),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _statusPill(bool paid) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (paid ? Colors.green : Colors.orange).withOpacity(.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: paid ? Colors.green : Colors.orange),
      ),
      child: Text(paid ? 'ĐÃ THANH TOÁN' : 'CHƯA THANH TOÁN', style: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w700,
        color: paid ? Colors.green.shade800 : Colors.orange.shade800,
      )),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(Icons.star_rounded, color: cs.primary),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ChecklistRow({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ]),
    );
  }
}
