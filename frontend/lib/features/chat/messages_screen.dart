import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../screens/chat_screen.dart';

class MessagesScreen extends StatelessWidget {
  final UserProfile user;
  const MessagesScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // demo conversations
    final items = [
      ('BS. An', 'Hẹn gặp bạn 9:00 sáng mai nhé.'),
      ('BS. Bình', 'Nhớ mang kết quả xét nghiệm lần trước.'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Tin nhắn')),
      body: items.isEmpty
          ? _empty(cs)
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final (name, last) = (items[i].$1, items[i].$2);
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: cs.secondaryContainer,
                      child: Text(name.characters.first.toUpperCase(),
                          style: TextStyle(color: cs.onSecondaryContainer, fontWeight: FontWeight.w800)),
                    ),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(last, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          roomId: 'general_chat',
                          senderId: user.id,
                          senderName: user.name,
                        ),
                      ));
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _empty(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.chat_bubble_outline, size: 56, color: cs.primary),
          const SizedBox(height: 10),
          Text('Chưa có tin nhắn', style: TextStyle(color: cs.onSurfaceVariant)),
        ]),
      ),
    );
  }
}
