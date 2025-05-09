import 'package:flutter/material.dart';

class AppointmentHistoryScreen extends StatelessWidget {
  const AppointmentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử đặt khám'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Lịch sử đặt khám sẽ hiển thị ở đây',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ),
    );
  }
}