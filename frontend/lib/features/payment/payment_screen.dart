import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:vietqr_core/vietqr_core.dart';
import 'package:vietqr_widget/vietqr_widget.dart';

import '../../models/appointment.dart';
import '../../utils/format.dart';

class PaymentScreen extends StatefulWidget {
  final Appointment appt;
  const PaymentScreen({super.key, required this.appt});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late VietQrData _currentQrData;

  @override
  void initState() {
    super.initState();
    _currentQrData = _buildVietQrDataFromAppt(widget.appt);
  }

  VietQrData _buildVietQrDataFromAppt(Appointment a) {
  final ref = 'APPT-${a.id.length > 5 ? a.id.substring(a.id.length - 5) : a.id}';
    return VietQrData(
      bankBinCode: a.doctor.bank,
      bankAccount: a.doctor.account,
      // Only set amount for static QR when amount > 0. Avoid sending "0".
      amount: (a.amount != null && a.amount! > 0) ? a.amount!.toString() : null,
      merchantName: a.doctor.name,  // ≤25
      merchantCity: a.doctor.city,  // ≤15
      additional: AdditionalData(
        purpose: 'Thanh toan $ref',
        referenceLabel: ref,
        storeLabel: 'MobileApp',
      ),
    );
  }


  Future<void> _confirmPaid() async {
    final ref = await showDialog<String>(
      context: context,
      builder: (_) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('Xác nhận đã chuyển khoản'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(labelText: 'Mã giao dịch (tuỳ chọn)'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('HỦY')),
            FilledButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: const Text('XONG')),
          ],
        );
      },
    );

    final updated = widget.appt.copyWith(
      paymentStatus: 'PAID',
      paymentRef: (ref?.isEmpty ?? true) ? null : ref,
    );
    if (!mounted) return;
    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.appt;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán (VietQR)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Thông tin lịch hẹn
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.person_outline),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Bác sĩ: ${a.doctor.name} – ${a.doctor.specialty}')),
                  ]),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.event_outlined),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Lịch: ${a.time}')),
                  ]),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.payments_outlined),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Số tiền: ${a.amount == null ? "Nhập khi quét (QR động)" : "${formatThousands(a.amount!)} VND"}',
                      ),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.account_balance_outlined),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Số tài khoản (QR): ${a.doctor.account}', style: TextStyle(color: Colors.blue))),
                  ]),
                ],
              ),
            ),
          ),

          // QR + nút hành động
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                children: [
                  Text('Quét để thanh toán', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Container(
                    width: 280,
                    height: 280,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cs.outlineVariant),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: VietQrWidget(
                      data: _currentQrData,
                      // embeddedImage: EmbeddedImage(scale: 0.2, image: AssetImage('assets/logo.png')),
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Text(
                          error.toString(),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          // Debug: print VietQrData and payload so we can inspect fields
                          try {
                            debugPrint('=== VietQrData (to be encoded) ===');
                            debugPrint(_currentQrData.toString());
                          } catch (_) {}
                          final payload = VietQr.encode(_currentQrData);
                          try {
                            debugPrint('=== VietQr Payload ===');
                            debugPrint(payload);
                          } catch (_) {}
                          Clipboard.setData(ClipboardData(text: payload));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã copy payload')),
                          );
                        },
                        icon: const Icon(Icons.copy_all),
                        label: const Text('Copy payload'),
                      ),
                      FilledButton.icon(
                        onPressed: _confirmPaid,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('ĐÃ THANH TOÁN'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget phụ: hiệu ứng phóng QR khi đổi dữ liệu
class _AnimatedVietQrWidget extends StatefulWidget {
  final VietQrData qrData;
  const _AnimatedVietQrWidget({required this.qrData});

  @override
  State<_AnimatedVietQrWidget> createState() => _AnimatedVietQrWidgetState();
}

class _AnimatedVietQrWidgetState extends State<_AnimatedVietQrWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  VietQrData? _previousQrData;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
    _previousQrData = widget.qrData;
  }

  @override
  void didUpdateWidget(covariant _AnimatedVietQrWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.qrData != _previousQrData) {
      _animationController.reset();
      _animationController.forward();
      _previousQrData = widget.qrData;
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]);
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: 280,
                  height: 280,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: VietQrWidget(
                    data: widget.qrData,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Text(
                          error.toString(),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'QR Code for ${widget.qrData.merchantName.isNotEmpty ? widget.qrData.merchantName : "Payment"}',
            style: text,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
