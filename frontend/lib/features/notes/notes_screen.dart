import 'package:flutter/material.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ghi chú sau khám')),
      body: const Center(
        child: Text('Form ghi chú: TODO – bổ sung sau'),
      ),
    );
  }
}
