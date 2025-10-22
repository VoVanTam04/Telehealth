import 'package:flutter/material.dart';
import '../../../models/user_profile.dart';
import '../../../models/appointment.dart';
// import '../../../data/mock_data.dart';
import '../../../services/appointment_service.dart';
import 'appointment_detail_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  final UserProfile user;
  const AppointmentsScreen({super.key, required this.user});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final _items = <Appointment>[];
  String _filter = 'ALL'; // ALL | UPCOMING | UNPAID | COMPLETED

  @override
  void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) => _fetchAppointments());
  }

  Future<void> _fetchAppointments() async {
    try {
      final list = await AppointmentService().listMine(
        role: 'patient',
        userId: int.tryParse(widget.user.id) ?? 0,
      );
      if (!mounted) return;
      setState(() {
        _items.clear();
        _items.addAll(list);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được lịch: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final list = _filtered();

    return Scaffold(
      appBar: AppBar(title: const Text('Lịch hẹn của tôi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(spacing: 8, children: [
            _chip(context, 'ALL', 'Tất cả'),
            _chip(context, 'UPCOMING', 'Sắp tới'),
            _chip(context, 'UNPAID', 'Chưa thanh toán'),
            _chip(context, 'COMPLETED', 'Đã xong'),
          ]),
          const SizedBox(height: 12),

          if (list.isEmpty) _empty(cs) else ...list.map((a)=>_tile(context, a)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  ChoiceChip _chip(BuildContext ctx, String key, String label) {
    final cs = Theme.of(ctx).colorScheme;
    final selected = _filter == key;
    return ChoiceChip(
      label: Text(label, style: TextStyle(
        fontWeight: FontWeight.w600,
        color: selected ? cs.onPrimary : cs.onSurface,
      )),
      selected: selected,
      showCheckmark: false,
      selectedColor: cs.primary,
      backgroundColor: cs.surface,
      side: BorderSide(color: selected ? cs.primary : cs.outlineVariant),
      onSelected: (_)=> setState(()=> _filter = key),
    );
  }

  List<Appointment> _filtered() {
    final now = DateTime.now();
    return _items.where((a){
      switch (_filter) {
        case 'UPCOMING': return a.time.isAfter(now);
        case 'UNPAID'  : return a.paymentStatus != 'PAID';
        case 'COMPLETED': return a.paymentStatus=='PAID' && a.time.isBefore(now);
        default: return true;
      }
    }).toList()..sort((a,b)=> a.time.compareTo(b.time));
  }

  Widget _empty(ColorScheme cs){
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(children:[
        Icon(Icons.event_busy, color: cs.primary, size: 36),
        const SizedBox(width: 12),
        Expanded(child: Text('Chưa có lịch hẹn phù hợp bộ lọc.', style: TextStyle(color: cs.onSurfaceVariant))),
      ]),
    );
  }

  Widget _tile(BuildContext context, Appointment appt){
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
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: cs.secondaryContainer,
          child: Text(appt.doctor.name.characters.first.toUpperCase(),
              style: TextStyle(color: cs.onSecondaryContainer, fontWeight: FontWeight.w800)),
        ),
        title: Text(appt.doctor.name, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${appt.doctor.specialty} · '
              '${appt.time.day.toString().padLeft(2, '0')}/'
              '${appt.time.month.toString().padLeft(2, '0')}/'
              '${appt.time.year} '
              '${appt.time.hour.toString().padLeft(2, '0')}:${appt.time.minute.toString().padLeft(2, '0')}'
            ),
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
                  color: paid ? Colors.green.shade800 : Colors.orange.shade800,
                )),
              ),
            ]),
          ],
        ),
        onTap: () async {
          // Nếu chi tiết lịch hẹn trả về true (đã thao tác), reload lại danh sách
          final result = await Navigator.push(context, MaterialPageRoute(
            builder: (_) => AppointmentDetailScreen(appt: appt, userName: widget.user.name, userId: widget.user.id),
          ));
          if (result == true) await _fetchAppointments();
        },
      ),
    );
  }
}
