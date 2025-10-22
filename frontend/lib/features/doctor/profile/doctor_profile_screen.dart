import 'package:flutter/material.dart';
import '../../../app_config.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../services/avatar_upload_service.dart';
import '../../../models/user_profile.dart';
import '../../../services/doctor_service.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/change_password_screen.dart';
final _auth = AuthService();

class DoctorProfileScreen extends StatefulWidget {
  final UserProfile user;
  const DoctorProfileScreen({super.key, required this.user});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  File? _avatarFile;
  String? _avatarUrl;
  final ImagePicker _picker = ImagePicker();
  // form state
  String _name = '';
  String _specialty = '';
  String _city = '';
  int _fee = 0;
  String _bank = '';        // lưu dạng lowercase cho BE
  String _account = '';

  bool _loading = true;
  bool _saving = false;

  // demo trong ngày (chưa lưu BE – mở rộng sau)
  bool _openToday = true;
  TimeOfDay _start = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _end   = const TimeOfDay(hour: 17, minute: 0);

  final _banks = const [
    'bidv','techcombank','vietcombank','acb','mb','vpbank','tpbank','sacombank','agribank'
  ];

  // ⬇️ Sửa dứt điểm: luôn trả về int
  int get _doctorId {
    final dynamic anyId = widget.user.id;
    if (anyId is int) return anyId;
    if (anyId is String) return int.tryParse(anyId) ?? 0;
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _name = widget.user.name;
    _loadProfile();
  }

  Future<void> _pickAvatar() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() {
        _avatarFile = File(picked.path);
      });
      try {
        final result = await AvatarUploadService.uploadAvatar(_doctorId, _avatarFile!);
        if (result != null) {
          await _loadProfile();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật ảnh đại diện thành công')),
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lỗi upload ảnh lên server')),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi upload ảnh: $e')),
        );
      }
    }
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final doc = await DoctorService().getDoctor(_doctorId);
      setState(() {
        _specialty = (doc.specialty ?? '').trim();
        _fee       = doc.fee ?? 0;
        _bank      = (doc.bank ?? 'bidv').toLowerCase();
        _account   = (doc.bankAccount ?? '').trim();
        _city      = (doc.city ?? '').trim();
        _avatarUrl = doc.avatar;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tải được hồ sơ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      await DoctorService().updateProfile(
        id: _doctorId,
        specialty: _specialty.isEmpty ? null : _specialty,
        fee: _fee < 0 ? 0 : _fee,
        bank: _bank.isEmpty ? null : _bank.toLowerCase(),
        bankAccount: _account.isEmpty ? null : _account,
        city: _city.isEmpty ? null : _city,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu hồ sơ bác sĩ')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lưu thất bại: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ bác sĩ'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadProfile,
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              onPressed: (_loading || _saving) ? null : _saveProfile,
              icon: _saving
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('Lưu'),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _avatarFile != null
                          ? CircleAvatar(
                              radius: 40,
                              backgroundImage: FileImage(_avatarFile!),
                            )
                          : (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                              ? CircleAvatar(
                                  radius: 40,
                                  backgroundImage: NetworkImage(
                                    _avatarUrl!.startsWith('http')
                                        ? _avatarUrl!
                                        : '${AppConfig.apiBase}${_avatarUrl!}',
                                  ),
                                )
                              : CircleAvatar(
                                  radius: 40,
                                  backgroundColor: cs.primaryContainer,
                                  child: Text(
                                    _name.isNotEmpty ? _name.characters.first.toUpperCase() : 'B',
                                    style: TextStyle(
                                      color: cs.onPrimaryContainer,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 24,
                                    ),
                                  ),
                                ),
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: Material(
                          color: cs.primary,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _pickAvatar,
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(Icons.edit, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                _section('Thông tin'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(children: [
                      _editableTile(
                        label: 'Họ tên (hiển thị)',
                        value: _name, // luôn là String
                        onEdit: () async {
                          final v = await _prompt('Họ tên', _name);
                          if (v != null) setState(() => _name = v);
                        },
                        // Lưu ý: name hiện đang chỉ hiển thị ở FE. Nếu muốn lưu BE, thêm PATCH /users/:id.
                      ),
                      const Divider(height: 1),
                      _editableTile(
                        label: 'Chuyên khoa',
                        value: _specialty.isEmpty ? '—' : _specialty,
                        onEdit: () async {
                          final v = await _prompt('Chuyên khoa', _specialty);
                          if (v != null) setState(() => _specialty = v);
                        },
                      ),
                      const Divider(height: 1),
                      _editableTile(
                        label: 'Thành phố',
                        value: _city.isEmpty ? '—' : _city,
                        onEdit: () async {
                          final v = await _prompt('Thành phố', _city);
                          if (v != null) setState(() => _city = v);
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Phí khám (đ)'),
                        subtitle: Text('$_fee'),
                        trailing: const Icon(Icons.edit_outlined),
                        onTap: () async {
                          final v = await _prompt('Phí khám (đ)', _fee.toString(),
                              keyboard: TextInputType.number);
                          if (v != null) {
                            final n = int.tryParse(v.replaceAll('.', '').replaceAll(',', '')) ?? 0;
                            setState(() => _fee = n < 0 ? 0 : n);
                          }
                        },
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),

                _section('Thời gian làm việc'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(children: [
                      SwitchListTile.adaptive(
                        title: const Text('Nhận khám hôm nay'),
                        value: _openToday,
                        onChanged: (v) => setState(() => _openToday = v),
                      ),
                      const SizedBox(height: 6),
                      Row(children: [
                        Expanded(child: _timeTile(context, 'Bắt đầu', _start, (t) => setState(() => _start = t))),
                        const SizedBox(width: 10),
                        Expanded(child: _timeTile(context, 'Kết thúc', _end, (t) => setState(() => _end = t))),
                      ]),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),

                _section('Ngân hàng nhận tiền'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(children: [
                      // Bank picker
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Ngân hàng'),
                        subtitle: Text(_bank.isEmpty ? '—' : _bank.toUpperCase()),
                        trailing: const Icon(Icons.edit_outlined),
                        onTap: () async {
                          final v = await _pickBank();
                          if (v != null) setState(() => _bank = v);
                        },
                      ),
                      const Divider(height: 1),
                      _editableTile(
                        label: 'Số tài khoản',
                        value: _account.isEmpty ? '—' : _account,
                        onEdit: () async {
                          final v = await _prompt('Số tài khoản', _account, keyboard: TextInputType.number);
                          if (v != null) setState(() => _account = v);
                        },
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),

                _section('Bảo mật'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(children: [
                      ListTile(
                        leading: const Icon(Icons.lock_reset),
                        title: const Text('Đổi mật khẩu'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChangePasswordScreen(
                                email: widget.user.email,
                                onChangePassword: _auth.changePassword,
                              ),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.logout),
                        title: const Text('Đăng xuất'),
                        onTap: () => Navigator.of(context)
                            .pushNamedAndRemoveUntil('/login', (route) => false),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
    );
  }

  Widget _section(String t) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(Icons.star_rounded, color: cs.primary),
        const SizedBox(width: 8),
        Text(t, style: const TextStyle(fontWeight: FontWeight.w800)),
      ]),
    );
  }

  // ⬇️ Cho phép value nullable để tránh lỗi “Null không gán được cho String”
  Widget _editableTile({
    required String label,
    required String? value,
    required Future<void> Function() onEdit,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(value ?? '—'),
      trailing: const Icon(Icons.edit_outlined),
      onTap: onEdit,
    );
  }

  Future<String?> _prompt(String title, String initial, {TextInputType? keyboard}) async {
    final ctrl = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(controller: ctrl, keyboardType: keyboard, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: const Text('Lưu')),
        ],
      ),
    );
  }

  Future<String?> _pickBank() async {
    String current = _bank.isEmpty ? _banks.first : _bank;
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Chọn ngân hàng'),
        content: SizedBox(
          width: 380,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _banks.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final b = _banks[i];
              final selected = b == current;
              return ListTile(
                title: Text(b.toUpperCase()),
                trailing: selected ? const Icon(Icons.check, color: Colors.green) : null,
                onTap: () => Navigator.pop(context, b),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
        ],
      ),
    );
  }

  // ✅ Fix overflow bằng Expanded + ellipsis
  Widget _timeTile(
    BuildContext context,
    String label,
    TimeOfDay v,
    ValueChanged<TimeOfDay> onPick,
  ) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () async {
        final t = await showTimePicker(context: context, initialTime: v);
        if (t != null) onPick(t);
      },
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$label: ${v.format(context)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
