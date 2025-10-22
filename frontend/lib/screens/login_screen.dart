import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_profile.dart';
import '../features/patient/patient_shell.dart';
import '../features/doctor/doctor_shell.dart';

/// Widget màn hình đăng nhập của ứng dụng.
/// Bao gồm form nhập tài khoản/mật khẩu, nút đăng nhập, và popup đăng ký tài khoản.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/// State của LoginScreen.
/// Xử lý logic đăng nhập, đăng ký, và điều hướng người dùng sau khi đăng nhập.
class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  final _auth = AuthService(); // Đối tượng xử lý đăng nhập/đăng ký

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  /// Hàm xử lý đăng nhập tài khoản
  Future<void> _onSubmit() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;
    setState(() => _loading = true);
    try {
      final UserProfile user = await _auth.signIn(
        identifier: _userCtrl.text,
        password: _passCtrl.text,
      );

      if (!mounted) return;

      // Điều hướng theo vai trò người dùng
      if (user.role.toLowerCase() == 'doctor') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => DoctorShell(user: user)),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => PatientShell(user: user)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Hàm hiển thị dialog popup đăng ký tài khoản mới
  /// Gửi dữ liệu lên backend để tạo tài khoản
  void _showRegisterDialog() {
    final _nameCtrl = TextEditingController();
    final _emailCtrl = TextEditingController();
    final _passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Đăng ký tài khoản'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Nhập tên
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Tên'),
            ),
            // Nhập email
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            // Nhập mật khẩu
            TextField(
              controller: _passCtrl,
              decoration: const InputDecoration(labelText: 'Mật khẩu'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          // Nút hủy dialog
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          // Nút đăng ký
          ElevatedButton(
            onPressed: () async {
              try {
                await _auth.register(
                  name: _nameCtrl.text,
                  email: _emailCtrl.text,
                  password: _passCtrl.text,
                );
                if (!mounted) return;
                Navigator.of(context).pop(); // Đóng dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đăng ký thành công, vui lòng đăng nhập!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                );
              }
            },
            child: const Text('Đăng ký'),
          ),
        ],
      ),
    );
  }

  /// Build UI chính của màn hình đăng nhập
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Nền gradient trang trí
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7DA7FF), Color(0xFF9ADAE0), Color(0xFFA8B4FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Hạt trang trí
          Positioned(
            right: 18,
            bottom: 18,
            child: Opacity(opacity: 0.4, child: _sparkle()),
          ),

          // Nội dung chính
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _logoBadge(),
                      const SizedBox(height: 20),
                      const Text(
                        'Telehealth',
                        style: TextStyle(
                          fontSize: 36, fontWeight: FontWeight.w800,
                          letterSpacing: 0.2, color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 22),

                      Container(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white.withOpacity(0.28)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 30,
                              offset: const Offset(0, 18),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _pillField(
                                controller: _userCtrl,
                                hint: 'Tên đăng nhập hoặc Email',
                                icon: Icons.person_outline,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) =>
                                  (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tài khoản' : null,
                              ),
                              const SizedBox(height: 12),
                              _pillField(
                                controller: _passCtrl,
                                hint: 'Mật khẩu',
                                icon: Icons.lock_outline,
                                obscure: _obscure,
                                suffix: IconButton(
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                                ),
                                validator: (v) => (v ?? '').length < 6 ? 'Tối thiểu 6 ký tự' : null,
                              ),
                              const SizedBox(height: 16),

                              // Nút đăng nhập
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3F74FF),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                  ),
                                  onPressed: _loading ? null : _onSubmit,
                                  child: _loading
                                      ? const SizedBox(
                                          width: 22, height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation(Colors.white),
                                          ),
                                        )
                                      : const Text('Đăng nhập',
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                ),
                              ),

                              const SizedBox(height: 10),

                              // Row cho "Forgot password" & "Tạo tài khoản"
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextButton(
                                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Quên mật khẩu (demo)')),
                                    ),
                                    child: const Text('Quên mật khẩu?'),
                                  ),
                                  const SizedBox(width: 6),
                                  TextButton(
                                    onPressed: _showRegisterDialog, // Gọi hàm show popup đăng ký
                                    child: const Text('Tạo tài khoản'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget trang trí (hình “sparkle” nhỏ dưới góc màn hình)
  Widget _sparkle() => CustomPaint(size: const Size(26, 26), painter: _SparklePainter());

  /// Widget logo Telehealth (badge hình trái tim, điện tim...)
  Widget _logoBadge() {
    return Container(
      width: 116, height: 116,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.20),
        border: Border.all(color: Colors.white.withOpacity(0.35)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 14))],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.favorite_border, size: 62, color: Colors.white.withOpacity(0.95)),
          Positioned(
            top: 34,
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.monitor_heart_outlined, color: Color(0xFF2DA8AA), size: 20),
            ),
          ),
          const Positioned(right: 28, top: 28, child: CircleAvatar(radius: 4, backgroundColor: Colors.white)),
        ],
      ),
    );
  }

  /// Widget field nhập liệu kiểu bo tròn đẹp cho login/register
  Widget _pillField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        filled: true,
        fillColor: Colors.white.withOpacity(0.85),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withOpacity(0.0)),
          borderRadius: BorderRadius.circular(28),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black.withOpacity(0.06)),
          borderRadius: BorderRadius.circular(28),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.redAccent),
          borderRadius: BorderRadius.circular(28),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.redAccent),
          borderRadius: BorderRadius.circular(28),
        ),
      ),
    );
  }
}

/// Custom painter cho hiệu ứng “sparkle” trang trí
class _SparklePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final path = Path();
    final w = size.width, h = size.height;
    path.moveTo(w / 2, 0);
    path.quadraticBezierTo(w * 0.55, h * 0.35, w, h / 2);
    path.quadraticBezierTo(w * 0.55, h * 0.65, w / 2, h);
    path.quadraticBezierTo(w * 0.45, h * 0.65, 0, h / 2);
    path.quadraticBezierTo(w * 0.45, h * 0.35, w / 2, 0);
    canvas.save();
    canvas.rotate(0.6);
    canvas.translate(-3, 2);
    canvas.drawPath(path, paint);
    canvas.restore();
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
