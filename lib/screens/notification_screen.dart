import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Chưa có thông báo nào.',
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}
