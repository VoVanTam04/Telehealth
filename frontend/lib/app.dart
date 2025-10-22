import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Login trước, rồi mới sang chọn vai
import 'screens/login_screen.dart';
import 'features/role/role_select_screen.dart';

class TelehealthApp extends StatelessWidget {
  const TelehealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xFF4C6FFF),
      textTheme: GoogleFonts.interTextTheme(),
    );

    return MaterialApp(
      title: 'Telehealth + VietQR (FE only)',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        appBarTheme: const AppBarTheme(centerTitle: true),

        // ✅ Sửa CardThemeData (thay vì CardTheme)
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),

        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          filled: true,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),

        chipTheme: base.chipTheme.copyWith(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
        snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      ),

      // Vào thẳng Login
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/role': (_) => const RoleSelectScreen(),
      },
    );
  }
}
