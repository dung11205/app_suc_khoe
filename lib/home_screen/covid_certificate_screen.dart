import 'package:flutter/material.dart';

class CovidCertificateScreen extends StatelessWidget {
  const CovidCertificateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chứng nhận ngừa Covid')),
      body: const Center(child: Text('Trang Chứng nhận ngừa Covid')),
    );
  }
}
