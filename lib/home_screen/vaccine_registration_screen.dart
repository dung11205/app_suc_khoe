import 'package:flutter/material.dart';

class VaccineRegistrationScreen extends StatelessWidget {
  const VaccineRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký tiêm chủng')),
      body: const Center(child: Text('Trang Đăng ký tiêm chủng')),
    );
  }
}
