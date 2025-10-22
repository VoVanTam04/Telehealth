import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import 'schedule/doctor_schedule_screen.dart';
import 'patients/doctor_patients_screen.dart';
import '../chat/messages_screen.dart';
import 'wallet/doctor_earnings_screen.dart';
import 'profile/doctor_profile_screen.dart';

class DoctorShell extends StatefulWidget {
  final UserProfile user;
  const DoctorShell({super.key, required this.user});

  @override
  State<DoctorShell> createState() => _DoctorShellState();
}

class _DoctorShellState extends State<DoctorShell> {
  int _idx = 0;
  late final _pages = <Widget>[
    DoctorScheduleScreen(user: widget.user),
    DoctorPatientsScreen(user: widget.user),
    MessagesScreen(user: widget.user), // tái dùng màn chat list
    DoctorEarningsScreen(user: widget.user),
    DoctorProfileScreen(user: widget.user),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: IndexedStack(index: _idx, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (v) => setState(() => _idx = v),
        indicatorColor: cs.primary.withOpacity(.12),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.event_note_outlined), label: 'Lịch khám'),
          NavigationDestination(icon: Icon(Icons.group_outlined), label: 'Bệnh nhân'),
          NavigationDestination(icon: Icon(Icons.chat_outlined), label: 'Tin nhắn'),
          NavigationDestination(icon: Icon(Icons.wallet_outlined), label: 'Doanh thu'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Hồ sơ'),
        ],
      ),
    );
  }
}
