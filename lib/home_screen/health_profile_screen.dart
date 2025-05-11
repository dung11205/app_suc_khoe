import 'package:flutter/material.dart';

class HealthProfileScreen extends StatelessWidget {
  const HealthProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ sức khỏe')),
      body: const Center(child: Text('Trang Hồ sơ sức khỏe')),
    );
  }
}
