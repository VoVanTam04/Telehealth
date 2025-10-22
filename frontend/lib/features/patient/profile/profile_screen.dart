import '../../../widgets/change_password_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../services/avatar_upload_service.dart';
  /// Mở màn hình đổi mật khẩu mới
  
import 'package:flutter/material.dart';
import '../../../app_config.dart';
import '../../../models/user_profile.dart';
import '../../../services/auth_service.dart'; // Để gọi đổi mật khẩu
import '../../../services/user_api_service.dart';

/// Màn hình Hồ sơ người dùng, cho phép xem/sửa thông tin và đổi mật khẩu.
typedef ProfileUpdatedCallback = void Function(UserProfile newUser);

class ProfileScreen extends StatefulWidget {
  final UserProfile user;
  final ProfileUpdatedCallback? onProfileUpdated;
  const ProfileScreen({super.key, required this.user, this.onProfileUpdated});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}


class _ProfileScreenState extends State<ProfileScreen> {
  File? _avatarFile;
  String? _avatarUrl;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAvatar() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() {
        _avatarFile = File(picked.path);
      });
      try {
        // Gọi service upload avatar
        final result = await AvatarUploadService.uploadAvatar(int.parse(widget.user.id), _avatarFile!);
        if (result != null) {
          await _loadUserProfile();
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
  late String _name;
  String _gender = 'Khác';
  DateTime? _dob;
  String _phone = '';
  String _email = '';
  String _address = '';
  final _auth = AuthService(); // Dùng để gọi API đổi mật khẩu
  final _userApi = UserApiService();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userMap = await _userApi.getUser(int.parse(widget.user.id));
      if (userMap != null) {
        setState(() {
          _name = userMap['name'] ?? '';
          _gender = userMap['gender'] ?? 'Khác';
          final birthdayStr = userMap['birthday'];
          _dob = birthdayStr != null && birthdayStr != '' ? DateTime.tryParse(birthdayStr) : null;
          _phone = userMap['phone'] ?? '';
          _email = userMap['email'] ?? '';
          _address = userMap['address'] ?? '';
          _avatarUrl = userMap['avatar'];
        });
      }
    } catch (e) {
      // ignore error, keep default values
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /// Ảnh đại diện + nút đổi ảnh (hiện chỉ demo)
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
                              _name.isNotEmpty ? _name.characters.first.toUpperCase() : '',
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
          const SizedBox(height: 16),

          /// Section thông tin cá nhân
          _section('Thông tin cá nhân'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                _field('Họ tên', _name, onEdit: () async {
                  final v = await _prompt(context, 'Họ tên', _name);
                  if (v != null && v != _name) {
                    setState(() => _name = v);
                    await _updateProfile({'name': v});
                  }
                }),
                _divider(),
                _field('Giới tính', _gender, onEdit: () async {
                  final v = await showDialog<String>(
                    context: context,
                    builder: (_) => SimpleDialog(
                      title: const Text('Chọn giới tính'),
                      children: [
                        SimpleDialogOption(onPressed: () => Navigator.pop(context, 'Nam'), child: const Text('Nam')),
                        SimpleDialogOption(onPressed: () => Navigator.pop(context, 'Nữ'), child: const Text('Nữ')),
                        SimpleDialogOption(onPressed: () => Navigator.pop(context, 'Khác'), child: const Text('Khác')),
                      ],
                    ),
                  );
                  if (v != null && v != _gender) {
                    setState(() => _gender = v);
                    await _updateProfile({'gender': v});
                  }
                }),
                _divider(),
                _field('Ngày sinh', _dob == null ? 'Chưa đặt' : _dob!.toString().split(' ').first, onEdit: () async {
                  final now = DateTime.now();
                  final first = now.subtract(const Duration(days: 365 * 100));
                  final last = now;
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: first,
                    lastDate: last,
                    initialDate: _dob ?? DateTime(2000, 1, 1),
                  );
                  if (picked != null && picked != _dob) {
                    setState(() => _dob = picked);
                    await _updateProfile({'birthday': picked.toIso8601String()});
                  }
                }),
              ]),
            ),
          ),
          const SizedBox(height: 12),

          /// Section liên hệ
          _section('Liên hệ'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                _field('Số điện thoại', _phone.isEmpty ? 'Chưa đặt' : _phone, onEdit: () async {
                  final v = await _prompt(context, 'Số điện thoại', _phone, keyboard: TextInputType.phone);
                  if (v != null && v != _phone) {
                    setState(() => _phone = v);
                    await _updateProfile({'phone': v});
                  }
                }),
                _divider(),
                _field('Email', _email.isEmpty ? 'Chưa đặt' : _email, onEdit: () async {
                  final v = await _prompt(context, 'Email', _email, keyboard: TextInputType.emailAddress);
                  if (v != null && v != _email) {
                    setState(() => _email = v);
                    await _updateProfile({'email': v});
                  }
                }),
                _divider(),
                _field('Địa chỉ', _address.isEmpty ? 'Chưa đặt' : _address, onEdit: () async {
                  final v = await _prompt(context, 'Địa chỉ', _address);
                  if (v != null && v != _address) {
                    setState(() => _address = v);
                    await _updateProfile({'address': v});
                  }
                }),
              ]),
            ),
          ),
          const SizedBox(height: 12),

          /// Section bảo mật (đổi mật khẩu + đăng xuất)
          _section('Bảo mật'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                ListTile(
                  leading: const Icon(Icons.lock_reset),
                  title: const Text('Đổi mật khẩu'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _changePasswordScreen,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Đăng xuất'),
                  // ⬇️ Xoá toàn bộ stack và về Login
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

void _changePasswordScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangePasswordScreen(
          email: widget.user.email,
          onChangePassword: _auth.changePassword,
        ),
      ),
    );
  }
  /// Widget tiêu đề từng section
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

  /// Widget hiển thị từng dòng thông tin (có nút chỉnh sửa)
  Widget _field(String label, String value, {required VoidCallback onEdit}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(value),
      trailing: const Icon(Icons.edit_outlined),
      onTap: onEdit,
    );
  }

  /// Divider cho UI
  Widget _divider() => const Divider(height: 1);

  /// Hiển thị dialog chỉnh sửa text đơn giản
  Future<String?> _prompt(BuildContext context, String title, String initial, {TextInputType? keyboard}) async {
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


  /// Gọi API cập nhật profile
  Future<void> _updateProfile(Map<String, dynamic> data) async {
    try {
      await _userApi.updateUserProfile(int.parse(widget.user.id), data);
      // Fetch lại user mới nhất từ backend và cập nhật state
      await _loadUserProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật hồ sơ thành công')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cập nhật thất bại: $e')),
      );
    }
  }
}
