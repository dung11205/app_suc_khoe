import 'package:flutter/material.dart';

class FamilyMembersScreen extends StatelessWidget {
  const FamilyMembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thành viên gia đình'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Danh sách thành viên gia đình sẽ hiển thị ở đây',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ),
    );
  }
}