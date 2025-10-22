import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import 'patient_home_screen.dart';
import 'appointments/appointments_screen.dart';
import '../chat/messages_screen.dart';
import 'profile/profile_screen.dart';

class PatientShell extends StatefulWidget {
  final UserProfile user;
  const PatientShell({super.key, required this.user});

  @override
  State<PatientShell> createState() => _PatientShellState();
}

class _PatientShellState extends State<PatientShell> {
  int _idx = 0;
  late UserProfile _user = widget.user;

  void _refreshUser(UserProfile newUser) {
    setState(() => _user = newUser);
  }

  List<Widget> get _pages => [
    PatientHomeScreen(user: _user),
    AppointmentsScreen(user: _user),
    MessagesScreen(user: _user),
    ProfileScreen(user: _user, onProfileUpdated: _refreshUser),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: IndexedStack(index: _idx, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (v) => setState(() => _idx = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Trang chủ'),
          NavigationDestination(icon: Icon(Icons.event_note_outlined), label: 'Lịch hẹn'),
          NavigationDestination(icon: Icon(Icons.chat_outlined), label: 'Tin nhắn'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Hồ sơ'),
        ],
        indicatorColor: cs.primary.withOpacity(.12),
      ),
    );
  }
}
