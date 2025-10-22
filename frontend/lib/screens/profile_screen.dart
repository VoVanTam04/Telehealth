import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';

/// Màn hình hồ sơ cá nhân, cho phép xem/chỉnh sửa thông tin & đổi mật khẩu.
class ProfileScreen extends StatefulWidget {
  final UserProfile user;

  const ProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserProfile user;
  final AuthService _auth = AuthService();

  @override
  void initState() {
    super.initState();
    user = widget.user;
  }

  /// Hiện dialog đổi mật khẩu.
  void _showChangePasswordDialog() {
    final _oldPassCtrl = TextEditingController();
    final _newPassCtrl = TextEditingController();
    final _confirmPassCtrl = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Đổi mật khẩu'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nhập mật khẩu cũ
              TextFormField(
                controller: _oldPassCtrl,
                decoration: const InputDecoration(labelText: 'Mật khẩu hiện tại'),
                obscureText: true,
                validator: (v) => v == null || v.length < 6 ? 'Tối thiểu 6 ký tự' : null,
              ),
              // Nhập mật khẩu mới
              TextFormField(
                controller: _newPassCtrl,
                decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
                obscureText: true,
                validator: (v) => v == null || v.length < 6 ? 'Tối thiểu 6 ký tự' : null,
              ),
              // Nhập lại mật khẩu mới
              TextFormField(
                controller: _confirmPassCtrl,
                decoration: const InputDecoration(labelText: 'Nhập lại mật khẩu mới'),
                obscureText: true,
                validator: (v) =>
                    v != _newPassCtrl.text ? 'Mật khẩu nhập lại không khớp' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!(_formKey.currentState?.validate() ?? false)) return;
              try {
                // Gọi API đổi mật khẩu
                await _auth.changePassword(
                  email: user.id, // hoặc user.email nếu model có
                  oldPassword: _oldPassCtrl.text,
                  newPassword: _newPassCtrl.text,
                );
                if (!mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đổi mật khẩu thành công!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            },
            child: const Text('Đổi mật khẩu'),
          ),
        ],
      ),
    );
  }

  /// Build UI hồ sơ người dùng (có nút đổi mật khẩu)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Avatar và tên
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 38,
                  backgroundImage: user.avatar != null ? NetworkImage(user.avatar!) : null,
                  child: user.avatar == null ? const Icon(Icons.person, size: 40) : null,
                ),
                const SizedBox(height: 12),
                Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(user.role, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          const Divider(height: 32),
          // Nút đổi mật khẩu
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Đổi mật khẩu'),
            onTap: _showChangePasswordDialog,
          ),
        ],
      ),
    );
  }
}
