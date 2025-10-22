import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ChatScreen extends StatefulWidget {
  final String roomId;
  final String senderId;
  final String senderName;
  const ChatScreen({super.key, required this.roomId, required this.senderId, required this.senderName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map> _messages = [];
  final TextEditingController _controller = TextEditingController();
  late DatabaseReference chatRef;
  StreamSubscription? _chatSubscription;

  @override
  void initState() {
    super.initState();
    chatRef = FirebaseDatabase.instance.ref().child('chats').child(widget.roomId).child('messages');
    _chatSubscription = chatRef.onChildAdded.listen((event) {
      final msg = Map<String, dynamic>.from(event.snapshot.value as Map);
      if (!mounted) return;
      setState(() {
        _messages.add(msg);
      });
    });
  }

  Future<void> sendMessage(String text) async {
    final msg = {
      'senderId': widget.senderId,
      'senderName': widget.senderName,
      'text': text,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    await chatRef.push().set(msg);
    _controller.clear();
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final senderId = msg['senderId']?.toString() ?? '';
                final isMe = senderId == widget.senderId;
                final sender = (msg['senderName'] != null && (msg['senderName'] as String).trim().isNotEmpty)
                    ? msg['senderName']
                    : 'Không rõ';
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue.shade100 : Colors.grey.shade200,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg['text'] ?? '',
                          style: TextStyle(
                            color: isMe ? Colors.blue.shade900 : Colors.black87,
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sender,
                          style: TextStyle(
                            fontSize: 12,
                            color: isMe ? Colors.blue.shade700 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'Nhập tin nhắn...'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    if (_controller.text.trim().isNotEmpty) {
                      sendMessage(_controller.text.trim());
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}