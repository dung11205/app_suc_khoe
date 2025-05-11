import 'package:flutter/material.dart';

class VaccinePassportScreen extends StatelessWidget {
  const VaccinePassportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hộ chiếu vắc-xin')),
      body: const Center(child: Text('Trang Hộ chiếu vắc-xin')),
    );
  }
}
