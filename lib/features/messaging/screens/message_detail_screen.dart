import 'package:flutter/material.dart';

class MessageDetailScreen extends StatelessWidget {
  final String conversationId;

  const MessageDetailScreen({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Chat')));
}
