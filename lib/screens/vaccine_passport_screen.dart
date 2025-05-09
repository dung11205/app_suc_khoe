import 'package:flutter/material.dart';

class VaccinePassportScreen extends StatelessWidget {
  const VaccinePassportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hộ chiếu vắc-xin'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Thông tin hộ chiếu vắc-xin sẽ hiển thị ở đây',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ),
    );
  }
}