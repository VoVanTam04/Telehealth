import 'package:flutter/material.dart';
import '../../../models/user_profile.dart';
import 'package:telehealth/screens/chat_screen.dart';
import '../../notes/notes_screen.dart';

class DoctorPatientsScreen extends StatefulWidget {
  final UserProfile user;
  const DoctorPatientsScreen({super.key, required this.user});

  @override
  State<DoctorPatientsScreen> createState() => _DoctorPatientsScreenState();
}

class _DoctorPatientsScreenState extends State<DoctorPatientsScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // demo list từ mockAppointments (nếu bạn có); ở đây tạo tạm danh sách tên
    final items = <String>{'Nguyễn A','Trần B','Lê C','Phạm D','Võ E'}.where((n)=> n.toLowerCase().contains(_q.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Bệnh nhân')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Tìm theo tên…'),
            onChanged: (v)=> setState(()=> _q=v),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Không tìm thấy bệnh nhân.', style: TextStyle(color: cs.onSurfaceVariant)),
            ))
          else
            ...items.map((name)=> Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: cs.secondaryContainer,
                  child: Text(name.characters.first.toUpperCase(),
                      style: TextStyle(color: cs.onSecondaryContainer, fontWeight: FontWeight.w800)),
                ),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('Đã khám: 2 lần • Gần nhất: tuần trước', style: TextStyle(color: cs.onSurfaceVariant)),
                trailing: const Icon(Icons.chevron_right),
                onTap: (){
                  showModalBottomSheet(
                    context: context,
                    showDragHandle: true,
                    builder: (_) => _PatientActions(name: name, doctorId: widget.user.id),
                  );
                },
              ),
            )),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _PatientActions extends StatelessWidget {
  final String name;
  final String doctorId;
  const _PatientActions({required this.name, required this.doctorId});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.chat_outlined),
            title: const Text('Nhắn tin'),
            onTap: ()=> Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ChatScreen(
                roomId: '${doctorId}_$name',
                senderId: doctorId.toString(),
                senderName: name,
              ),
            )),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Ghi chú hồ sơ'),
            onTap: ()=> Navigator.of(context).push(MaterialPageRoute(builder: (_)=> const NotesScreen())),
          ),
        ]),
      ),
    );
  }
}
