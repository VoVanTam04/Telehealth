import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat trong phiên')),
      body: const Center(
        child: Text('Chat/File sharing: TODO – tích hợp sau'),
      ),
    );
  }
}
