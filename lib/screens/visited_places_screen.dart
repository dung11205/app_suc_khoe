import 'package:flutter/material.dart';

class VisitedPlacesScreen extends StatelessWidget {
  const VisitedPlacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nơi đã đến'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Danh sách nơi đã đến sẽ hiển thị ở đây',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ),
    );
  }
}