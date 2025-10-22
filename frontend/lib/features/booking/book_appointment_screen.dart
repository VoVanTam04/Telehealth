import 'package:flutter/material.dart';

import '../../utils/format.dart';
import '../../services/doctor_service.dart';
import '../../services/appointment_service.dart';

class BookAppointmentScreenNew extends StatefulWidget {
  final int patientId; // <-- nhận patientId thực
  const BookAppointmentScreenNew({super.key, required this.patientId});

  @override
  State<BookAppointmentScreenNew> createState() => _BookAppointmentScreenNewState();
}

class _BookAppointmentScreenNewState extends State<BookAppointmentScreenNew> {
  DoctorBrief? _selected;
  DateTime _time = DateTime.now().add(const Duration(days: 1, hours: 2));
  final _noteCtrl = TextEditingController();
  bool _staticAmount = true;
  final _amountCtrl = TextEditingController(text: '50000');

  bool _loadingDoctors = true;
  final List<DoctorBrief> _doctors = <DoctorBrief>[];

  // Slot trống
  List<DateTime> _slots = [];
  bool _loadingSlots = false;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  // ================== DATA LOADERS ==================

  Future<void> _loadDoctors() async {
    setState(() => _loadingDoctors = true);
    try {
      // Lấy danh sách bác sĩ (không phân trang) cho đơn giản
  final ds = await DoctorService().listDoctors(); // -> List<DoctorBrief>
      if (!mounted) return;
      setState(() {
        _doctors
          ..clear()
          ..addAll(ds);
        if (_doctors.isNotEmpty) {
          _selected = _doctors.first;
          _amountCtrl.text = ((_selected!.fee ?? 0)).toString();
        }
      });
      // Sau khi chọn bác sĩ, tự động load slot trống cho ngày mai
      await _loadSlots();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được danh sách bác sĩ: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingDoctors = false);
    }
  }

  Future<void> _loadSlots() async {
    if (_selected == null) return;
    setState(() => _loadingSlots = true);
    try {
      final now = DateTime.now();
      final slots = await AppointmentService().getDoctorSlots(
        doctorId: _selected!.id,
        date: DateTime(now.year, now.month, now.day + 1), // slot ngày mai
      );
      if (!mounted) return;
      setState(() => _slots = slots);
    } catch (e) {
      if (!mounted) return;
      setState(() => _slots = []);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được slot: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingSlots = false);
    }
  }

  // ================== UI ==================

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Đặt lịch khám')),
      body: Stack(
        children: [
          // nền gradient phần trên
          Container(
            height: 240,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cs.primary.withOpacity(.18),
                  cs.tertiary.withOpacity(.16),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          if (_loadingDoctors)
            const Center(child: CircularProgressIndicator())
          else
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                const _SectionHeader(
                  icon: Icons.medical_services_outlined,
                  title: 'Chọn bác sĩ',
                  subtitle: 'Chuyên khoa phù hợp & phí dự kiến',
                ),
                _DoctorPicker(
                  doctors: _doctors,
                  selected: _selected,
                  onChanged: (d) async {
                    setState(() {
                      _selected = d;
                      if (_staticAmount && d != null) {
                        _amountCtrl.text = (d.fee ?? 0).toString();
                      }
                    });
                    await _loadSlots();
                  },
                ),

                const SizedBox(height: 12),
                const _SectionHeader(
                  icon: Icons.schedule_outlined,
                  title: 'Chọn slot trống',
                  subtitle: 'Chọn giờ khám còn trống của bác sĩ',
                ),
                if (_loadingSlots)
                  const Center(child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: CircularProgressIndicator(),
                  ))
                else if (_slots.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Không có slot trống nào cho ngày này.', style: TextStyle(color: Colors.redAccent)),
                  )
                else
                  SizedBox(
                    height: 48 * 4,
                    child: ListView.builder(
                      itemCount: _slots.length,
                      itemBuilder: (context, i) {
                        final slot = _slots[i];
                        final isSelected = slot == _time;
                        final hh = slot.hour.toString().padLeft(2, '0');
                        final mm = slot.minute.toString().padLeft(2, '0');
                        final dd = slot.day.toString().padLeft(2, '0');
                        final mo = slot.month.toString().padLeft(2, '0');

                        return ListTile(
                          title: Text('$hh:$mm'),
                          subtitle: Text('$dd/$mo/${slot.year}'),
                          trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green) : null,
                          onTap: () => setState(() => _time = slot),
                          selected: isSelected,
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 12),
                const _SectionHeader(
                  icon: Icons.qr_code_2,
                  title: 'Cấu hình VietQR',
                  subtitle: 'QR cố định số tiền hoặc QR động',
                ),
                _QrConfigCard(
                  staticAmount: _staticAmount,
                  onToggle: (v) => setState(() {
                    _staticAmount = v;
                    if (v && _selected != null) {
                      _amountCtrl.text = (_selected!.fee ?? 0).toString();
                    }
                  }),
                  amountCtrl: _amountCtrl,
                ),

                const SizedBox(height: 16),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Tạo lịch'),
                    onPressed: _selected == null ? null : _createAppointment,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ================== ACTIONS ==================

  Future<void> _createAppointment() async {
    if (_selected == null) return;

    try {
      final created = await AppointmentService().create(
        patientId: widget.patientId,
        doctorId: _selected!.id,
        appointmentTime: _time,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        amount: _staticAmount ? int.tryParse(_amountCtrl.text) : null,
      );
      if (!mounted) return;
      Navigator.pop(context, created); // trả object từ backend về màn trước (nếu cần)
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tạo lịch thất bại: $e')),
      );
    }
  }
}

// ================== WIDGETS PHỤ ==================

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  const _SectionHeader({required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(.12),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: cs.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              if (subtitle != null)
                Text(subtitle!, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _DoctorPicker extends StatelessWidget {
  final List<DoctorBrief> doctors;
  final DoctorBrief? selected;
  final ValueChanged<DoctorBrief?> onChanged;
  const _DoctorPicker({
    required this.doctors,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            DropdownButtonFormField<DoctorBrief>(
              isExpanded: true,
              value: selected,
              menuMaxHeight: 340,
              decoration: const InputDecoration(hintText: 'Chọn bác sĩ...'),
              items: [
                for (final d in doctors)
                  DropdownMenuItem(
                    value: d,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: cs.secondaryContainer,
                          child: Text(
                            d.name.characters.first.toUpperCase(),
                            style: TextStyle(
                              color: cs.onSecondaryContainer,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          fit: FlexFit.loose,
                          child: Text(
                            '${d.name} · ${d.specialty ?? ''} · ${formatThousands(d.fee ?? 0)} đ',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              selectedItemBuilder: (context) => [
                for (final d in doctors)
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: cs.secondaryContainer,
                        child: Text(
                          d.name.characters.first.toUpperCase(),
                          style: TextStyle(
                            color: cs.onSecondaryContainer,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${d.name} · ${d.specialty ?? ''} · ${formatThousands(d.fee ?? 0)} đ',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
              ],
              onChanged: onChanged,
            ),
            if (selected != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cs.primaryContainer, cs.tertiaryContainer],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.payments_rounded, color: cs.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Phí cơ bản: ${formatThousands((selected!.fee ?? 0))} đ • ${selected!.specialty ?? ''}',
                        style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QrConfigCard extends StatelessWidget {
  final bool staticAmount;
  final ValueChanged<bool> onToggle;
  final TextEditingController amountCtrl;

  const _QrConfigCard({
    required this.staticAmount,
    required this.onToggle,
    required this.amountCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            SwitchListTile.adaptive(
              title: const Text('QR có sẵn số tiền (Static Amount)'),
              subtitle: const Text('Tắt = QR động (nhập tiền khi quét)'),
              value: staticAmount,
              onChanged: onToggle,
            ),
            if (staticAmount) ...[
              const SizedBox(height: 8),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Số tiền (VND)',
                  prefixIcon: const Icon(Icons.attach_money),
                  suffixText: 'đ',
                  filled: true,
                  fillColor: cs.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Gợi ý: đặt bằng phí cơ bản của bác sĩ để bệnh nhân thanh toán trước.',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
